defmodule AppCount.Ledgers.Utils.Payments do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Tenants
  alias AppCount.Ledgers.Payment
  alias AppCount.Accounting.Receipt
  alias AppCount.Ledgers.Batch
  alias AppCount.Properties.Processors
  alias AppCount.RentApply.RentApplication
  alias AppCount.Core.ClientSchema

  def list_payments(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        %{
          "start" => start_date,
          "end" => end_date,
          "property_id" => property_id
        }
      ) do
    end_date =
      Timex.parse!(end_date, "{YYYY}-{M}-{D}")
      |> Timex.shift(days: 1)

    applicant_query =
      from(
        r in RentApplication,
        join: p in assoc(r, :persons),
        select: %{
          id: r.id,
          persons: jsonize(p, [:id, :full_name])
        },
        group_by: [r.id]
      )

    from(
      p in Payment,
      left_join: t in assoc(p, :tenant),
      left_join: te in subquery(AppCount.Tenants.TenancyRepo.latest_tenancy_query()),
      on: te.tenant_id == t.id,
      left_join: pr in assoc(p, :property),
      left_join: u in AppCount.Properties.Unit,
      on: u.id == te.unit_id,
      left_join: img in assoc(p, :image_url),
      join: batch in assoc(p, :batch),
      left_join: app in subquery(applicant_query),
      on: app.id == p.application_id,
      distinct: p.id,
      select:
        map(
          p,
          [
            :agreement_text,
            :agreement_accepted_at,
            :id,
            :transaction_id,
            :source,
            :description,
            :surcharge,
            :property_id,
            :tenant_id,
            :post_month,
            :payer,
            :status,
            :payer_ip_address,
            :zip_code_confirmed_at,
            :cvv_confirmed_at,
            :rent_application_terms_and_conditions
          ]
        ),
      select_merge: %{
        image: img.url,
        tenant_name: fragment("? || ' ' || ?", t.first_name, t.last_name),
        unit: u.number,
        property_name: pr.name,
        inserted_at: fragment("extract(EPOCH FROM ?)", p.inserted_at),
        amount: type(p.amount, :float),
        application_id: app.id,
        persons: app.persons,
        tenancy_id: te.id
      },
      where: pr.id in ^Admins.property_ids_for(ClientSchema.new("dasmen", admin)),
      where: pr.id == ^property_id,
      where: batch.inserted_at >= ^Timex.parse!(start_date, "{YYYY}-{M}-{D}"),
      where: batch.inserted_at < ^end_date,
      order_by: [
        desc: p.inserted_at
      ]
    )
    |> Repo.all(prefix: client_schema)
  end

  def create_admin_payment(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    %Payment{}
    |> Payment.changeset(params)
    |> Repo.insert(prefix: client_schema)
  end

  def create_payment(%AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    new_params =
      cond do
        is_nil(params["receipts"]) or length(params["receipts"]) > 1 ->
          params

        length(params["receipts"]) == 1 and
            Enum.at(params["receipts"], 0) == %{"amount" => 0, "id" => 1} ->
          Map.delete(params, "receipts")

        true ->
          params
      end

    %Payment{}
    |> Payment.changeset(new_params)
    |> Repo.insert(prefix: client_schema)
    |> case do
      {:ok, p} ->
        AppCount.Rewards.create_accomplishment(
          ClientSchema.new(client_schema, %{tenant_id: p.tenant_id, type: "Payment"})
        )

        create_receipts(ClientSchema.new(client_schema, p), new_params["receipts"])
        {:ok, p}

      e ->
        e
    end
  end

  def update_payment(admin, id, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    cs =
      Payment
      |> Repo.get(id, prefix: client_schema)
      |> Payment.changeset(params)

    if Enum.all?([:amount, :tenant_id, :inserted_at], &(!cs.changes[&1])) do
      cs
      |> log_changes(admin.name)
      |> Repo.update(prefix: client_schema)
    else
      void_and_duplicate(
        ClientSchema.new(
          client_schema,
          admin.name
        ),
        cs
      )
    end
  end

  def update_payment(id, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    Payment
    |> Repo.get(id, prefix: client_schema)
    |> Payment.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def delete_payment(admin, %AppCount.Core.ClientSchema{name: client_schema, attrs: id}) do
    if MapSet.member?(admin.roles, "Super Admin") do
      Repo.get(Payment, id, prefix: client_schema)
      |> AppCount.Admins.Utils.Actions.admin_delete(ClientSchema.new(client_schema, admin))
    end
  end

  def get_payment_image(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: id
      }) do
    from(p in Payment, join: u in assoc(p, :image_url), select: u.url, where: p.id == ^id)
    |> Repo.one(prefix: client_schema)
  end

  # Payment with tokenized data - 1 time payment
  # or Payment with stored payment method
  # TODO find where this is called ,  call Ports.CreditCardPort directly.
  def process_payment(property_id, amount, source) do
    case get_processor(property_id, source) do
      nil ->
        {:error, %{reason: "Property is not configured for payments at this time"}}

      processor ->
        Module.concat([processor.name])
        |> apply(:process_payment, [amount, source, processor])
    end
  end

  def clear_payments(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_id
      }) do
    prior_clear_date =
      AppCount.current_time()
      |> Timex.beginning_of_month()

    from(
      p in AppCount.Ledgers.Payment,
      where: p.property_id == ^property_id and p.inserted_at < ^prior_clear_date,
      select: p.id
    )
    |> AppCount.Repo.all(prefix: client_schema)
    |> Enum.each(fn x ->
      AppCount.Repo.get(Payment, x, prefix: client_schema)
      |> Repo.delete(prefix: client_schema)
    end)
  end

  def process_moneygram_payment(xml) do
    case MoneyGram.process_request(xml) do
      {:ok, %{amount: _} = load_request} -> create_money_gram_payment(load_request)
      {:ok, tenant_id} -> validate_money_gram(tenant_id)
    end
  end

  def handle_post_error(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: id
        },
        error
      ) do
    payment = Repo.get(Payment, id, prefix: client_schema)

    if String.match?(error, ~r"Payments from this tenant must be cash equivalent") do
      AppCount.Accounts.lock_account(
        payment.tenant_id,
        "Payments must be made in person in the office."
      )
    end

    payment
    |> Payment.changeset(%{post_error: error})
    |> Repo.update(prefix: client_schema)

    ClientSchema.new(client_schema, payment.property_id)
    |> AppCount.Admins.admins_for(["Admin"])
    |> Enum.each(fn admin ->
      AppCount.Admins.create_alert(
        ClientSchema.new(client_schema, %{
          sender: "AppRent",
          admin_id: admin.id,
          note:
            "Payment failed to post: #{AppCount.namespaced_url("administration")}/payments/#{
              payment.id
            }",
          flag: 4
        })
      )
    end)
  end

  defp void_and_duplicate(
         %AppCount.Core.ClientSchema{
           name: client_schema,
           attrs: admin
         },
         changes
       ) do
    changes.data
    |> Payment.changeset(%{
      status: "voided",
      transaction_id:
        new_transaction_id(ClientSchema.new(client_schema, changes.data.transaction_id))
    })
    |> Repo.update!(prefix: client_schema)

    params =
      changes.data
      |> Map.drop([:id, :__meta__, :__struct__, :image, :updated_at])
      |> Map.merge(changes.changes)
      |> Map.merge(%{admin: admin})
      |> case do
        %{tenant_id: _} = p -> Map.merge(p, %{lease_id: nil})
        p -> p
      end

    %Payment{}
    |> Payment.changeset(params)
    |> Repo.insert!(prefix: client_schema)
  end

  def new_transaction_id(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: transaction_id
      }) do
    transaction =
      String.split(transaction_id, "*")
      |> Enum.at(0)

    old_transaction_id =
      from(
        p in Payment,
        where: like(p.transaction_id, ^"%#{String.replace(transaction, "%", "\\%")}*%"),
        where: like(p.transaction_id, "%*%"),
        select: p.transaction_id,
        order_by: [
          desc: fragment("CHAR_LENGTH(?)", p.transaction_id)
        ],
        limit: 1
      )
      |> Repo.one(prefix: client_schema)

    "#{old_transaction_id || transaction_id}*"
  end

  defp validate_money_gram(property_and_tenant_id) do
    # TODO:SCHEMA remove dasmen
    client_schema = "dasmen"

    with {_property_id, tenant_id} <- String.split_at(property_and_tenant_id, 4),
         {_, ""} <- Integer.parse(tenant_id),
         id when not is_nil(id) <- Repo.get(Tenants.Tenant, tenant_id, prefix: client_schema) do
      MoneyGram.validation_response(status: "PASS", transaction_id: tenant_id, message: "SUCCESS")
    else
      _ ->
        MoneyGram.validation_response(
          status: "FAIL",
          transaction_id: moneygram_failed_transaction_id(property_and_tenant_id),
          error_code: "1010",
          message: "NO SUCH ACCOUNT"
        )
    end
  end

  defp create_money_gram_payment(%{
         amount: a,
         account_number: property_and_tenant_id,
         ref_number: ref
       }) do
    # TODO:SCHEMA remove and pass client_schema to this function
    client_schema = "dasmen"
    {_property_id, tenant_id} = String.split_at(property_and_tenant_id, 4)

    case AppCount.Tenants.Utils.Tenants.property_for(tenant_id) do
      nil ->
        MoneyGram.load_response(
          status: "FAIL",
          transaction_id: moneygram_failed_transaction_id(tenant_id),
          error_code: "1010",
          bpg_error_code: "01409",
          message: "NO SUCH ACCOUNT"
        )

      %{id: property_id} ->
        ba_id =
          Repo.get_by(AppCount.Properties.Setting, [property_id: property_id],
            prefix: client_schema
          ).default_bank_account_id

        batch =
          %Batch{}
          |> Batch.changeset(%{property_id: property_id, bank_account_id: ba_id})
          |> Repo.insert!(prefix: client_schema)

        ClientSchema.new(client_schema, %{
          property_id: property_id,
          tenant_id: tenant_id,
          amount: a,
          transaction_id: ref,
          source: "moneygram",
          description: "MoneyGram Payment",
          batch_id: batch.id
        })
        |> create_payment
        |> case do
          {:ok, %{id: id} = payment} ->
            AppCount.Core.Tasker.start(fn ->
              post_payment_create(ClientSchema.new(client_schema, tenant_id), payment)
            end)

            MoneyGram.load_response(status: "PASS", transaction_id: id, message: "SUCCESS")

          {:error, e} ->
            {field, {message, _}} = hd(e.errors)

            MoneyGram.load_response(
              status: "FAIL",
              transaction_id: moneygram_failed_transaction_id(property_and_tenant_id),
              error_code: "1003",
              bpg_error_code: "01409",
              message: "#{field} #{message}"
            )
        end
    end
  end

  # UNTESTED
  def post_payment_create(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: tenant_id
        },
        payment
      ) do
    tenant = Repo.get(AppCount.Tenants.Tenant, tenant_id, prefix: client_schema)

    property =
      AppCount.Tenants.Utils.Tenants.property_for(tenant.id)
      |> Repo.preload(:setting)

    if property.setting.sync_payments and property.setting.integration == "Yardi" and
         !!tenant.external_id do
      AppCount.Yardi.ExportPayment.export_payment(payment.id)
    end

    AppCountCom.Accounts.payment_received(tenant, payment, property)
  end

  defp get_processor(property_id, source) do
    Processors.fetch(property_id, source)
  end

  defp log_changes(%{changes: changes} = cs, _) when changes == %{}, do: cs

  defp log_changes(%{changes: changes} = cs, admin) do
    changed_attrs =
      Map.merge(changes, %{admin: admin, time: AppCount.current_time()})
      |> Map.delete(:image)

    edits = cs.data.edits ++ [changed_attrs]
    Ecto.Changeset.change(cs, %{edits: edits})
  end

  defp create_receipts(%AppCount.Core.ClientSchema{attrs: payment}, nil),
    do: payment

  defp create_receipts(%AppCount.Core.ClientSchema{name: client_schema, attrs: payment}, receipts) do
    Enum.each(
      receipts,
      fn r ->
        %Receipt{}
        |> Receipt.changeset(Map.merge(r, %{"payment_id" => payment.id}))
        |> Repo.insert!(prefix: client_schema)
      end
    )
  end

  defp moneygram_failed_transaction_id(id) do
    ts =
      AppCount.current_time()
      |> Timex.to_unix()

    "#{id}-#{ts}"
  end
end
