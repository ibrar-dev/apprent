defmodule AppCount.Accounts.Utils.Payments do
  alias AppCount.Repo
  alias AppCount.Accounts.Account
  alias AppCount.Accounts.PaymentSource
  alias AppCount.Ledgers.Payment
  alias AppCount.Ledgers.Utils.Payments
  alias AppCount.Ledgers.Batch
  alias AppCount.Tenants.Tenant
  alias AppCount.Properties.Settings
  alias AppCount.Core.Clock
  alias AppCount.Core.DateTimeRange
  import Ecto.Query
  use AppCount.Decimal
  alias AppCount.Core.ClientSchema

  def list_payments(user_id, limit \\ nil) do
    from(
      p in Payment,
      left_join: s in assoc(p, :payment_source),
      where: p.tenant_id == ^user_id,
      select: %{
        id: p.id,
        amount: p.amount,
        date: fragment("to_char(?, 'Month DD, YYYY HH:MI')", p.inserted_at),
        brand: s.brand,
        status: p.status,
        transaction_id: p.transaction_id,
        description: p.description,
        num: p.last_4
      },
      order_by: [
        desc: p.inserted_at
      ],
      limit: ^limit
    )
    |> Repo.all()
    |> Enum.map(fn payment ->
      Map.put(payment, :num, format_last_4(payment.num || payment.transaction_id))
    end)
  end

  @spec create_payment(map()) :: {:ok, any} | {:error, any}
  def create_payment(
        %{
          "account_id" => account_id,
          "amount" => amount,
          "payment_source_id" => ps_id,
          "agreement_text" => agreement_text,
          "agreement_accepted_at" => timestamp,
          "payer_ip_address" => payer_ip_address
        } = params
      ) do
    # Lock Payment source and return source.
    client_schema = "dasmen"
    source = lock_and_return_source(ps_id)

    lock_date = source.lock

    {property_id, tenant_id, tenant_external_id, sync_payments} =
      from(
        a in Account,
        join: t in assoc(a, :tenant),
        join: p in assoc(a, :property),
        join: s in assoc(p, :setting),
        where: a.id == ^account_id,
        select: {a.property_id, a.tenant_id, t.external_id, s.sync_payments}
      )
      |> Repo.one()

    surcharge = get_surcharge(source, amount)

    unless payment_source_in_cooldown?(lock_date) do
      Payments.process_payment(property_id, amount + surcharge, source)
      |> case do
        {:ok, response} ->
          # TODO:SCHEMA remove dasmen
          ba_id =
            Settings.fetch_by_property_id(ClientSchema.new(client_schema, property_id)).default_bank_account_id

          batch =
            %Batch{}
            |> Batch.changeset(%{property_id: property_id, bank_account_id: ba_id})
            |> Repo.insert!(prefix: client_schema)

          Payments.create_payment(
            ClientSchema.new(client_schema, %{
              agreement_text: agreement_text,
              agreement_accepted_at: timestamp,
              payer_ip_address: payer_ip_address,
              description: params["description"] || "AppRent Payment",
              source: params["source"] || "web",
              response: Map.delete(response, :transaction_id),
              transaction_id: response.transaction_id,
              amount: amount,
              surcharge: surcharge,
              tenant_id: tenant_id,
              property_id: property_id,
              payment_source_id: ps_id,
              batch_id: batch.id,
              last_4: source.last_4,
              payer_name: source.name,
              payment_type: source.type
            })
          )
          |> case do
            {:ok, payment} ->
              if !!tenant_external_id and sync_payments,
                do: AppCount.Yardi.ExportPayment.export_payment(payment.id)

              AppCount.Core.Tasker.start(fn ->
                tenant = Repo.get(Tenant, tenant_id)
                property = AppCount.Tenants.Utils.Tenants.property_for(tenant.id)

                AppCountCom.Accounts.payment_received(tenant, payment, property)
              end)

              {:ok, payment}

            e ->
              e
          end

        e ->
          e
      end
    else
      {:error, "Payment cooldown"}
    end
  end

  def lock_and_return_source(payment_source_id) do
    source = Repo.get(PaymentSource, payment_source_id)

    PaymentSource.changeset(source, %{lock: NaiveDateTime.utc_now()})
    |> Repo.update!()

    # We need to return the original lock time bc the rest of the create_payment/1 needs to function.
    %{source | lock: source.lock}
  end

  def payment_source_in_cooldown?(nil) do
    false
  end

  def payment_source_in_cooldown?(%PaymentSource{lock: lock_date}) do
    payment_source_in_cooldown?(lock_date)
  end

  def payment_source_in_cooldown?(payment_source_lock_date) do
    lock_date = Clock.to_utc(payment_source_lock_date)
    past_12_hours = DateTimeRange.last12hours()

    DateTimeRange.within?(past_12_hours, lock_date)
  end

  def format_last_4(string) do
    "XXXX XXXX XXXX #{string}"
  end

  # Temporarily remove surcharge on CC payments 03/31/20 -DA
  # Surcharge is supposed to be back in... 02/05/21 -DA
  defp get_surcharge(%{type: "cc"}, amount), do: round(amount * 3) / 100
  defp get_surcharge(_, _), do: 0
end
