defmodule AppCount.Ledgers.Utils.Batches do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Ledgers.Batch
  alias AppCount.Ledgers.Payment
  alias AppCount.Ledgers.Utils.Payments
  alias AppCount.Admins
  alias AppCount.Repo
  alias Ecto.Multi
  alias AppCount.RentApply.RentApplication
  alias AppCount.Properties.Settings
  alias AppCount.Core.ClientSchema

  def list_batches(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: admin},
        %{"start" => start_date, "end" => end_date} = p
      ) do
    admin_property_ids =
      Admins.property_ids_for(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin})

    params_property_ids = p["property_ids"]

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

    end_date =
      Timex.parse!(end_date, "{YYYY}-{M}-{D}")
      |> Timex.shift(days: 1)

    start_date = Timex.parse!(start_date, "{YYYY}-{M}-{D}")

    from(
      b in Batch,
      left_join: pa in assoc(b, :payments),
      left_join: pr in assoc(pa, :property),
      left_join: t in assoc(pa, :tenant),
      left_join: te in subquery(AppCount.Tenants.TenancyRepo.latest_tenancy_query()),
      on: te.tenant_id == t.id,
      left_join: ps in assoc(pa, :payment_source),
      left_join: u in AppCount.Properties.Unit,
      on: u.id == te.unit_id,
      left_join: app in subquery(applicant_query),
      on: app.id == pa.application_id,
      where: b.property_id in ^admin_property_ids,
      where: b.property_id in ^params_property_ids,
      where: b.inserted_at >= ^start_date,
      where: b.inserted_at < ^end_date,
      having: count(pa.id) > 0,
      select: map(b, [:id, :property_id, :date_closed, :closed_by, :inserted_at, :memo]),
      select_merge: %{
        total: sum(pa.amount),
        payments:
          jsonize(
            pa,
            [
              :id,
              :status,
              :amount,
              :surcharge,
              :payment_type,
              :tenant_id,
              :inserted_at,
              :description,
              :payer,
              :transaction_id,
              :post_month,
              :post_error,
              :source,
              {:tenancy_id, te.id},
              {:property_name, pr.name},
              {:unit, u.number},
              {:tenant_name, fragment("? || ' ' || ?", t.first_name, t.last_name)},
              {:batch_id, b.id},
              {:application_id, app.id},
              {:persons, app.persons},
              {:payment_source_last_4, ps.last_4}
            ]
          )
      },
      where: pa.status == "cleared" or pa.status == "nsf",
      group_by: [b.id]
    )
    |> Repo.all(timeout: 300_000, prefix: client_schema)
  end

  def check_valid(%AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    payment =
      if(params["description"] == "Money Order") do
        Repo.get_by(
          Payment,
          [transaction_id: params["transaction_id"], description: "Money Order"],
          prefix: client_schema
        )
      else
        nil
      end

    %Payment{}
    |> Payment.changeset(params)
    |> find_valid(payment)
  end

  defp find_valid(%{valid?: true}, payment) when is_nil(payment), do: {:ok, %{}}

  defp find_valid(%{valid?: true}, payment) when not is_nil(payment),
    do: {:error, "Transaction: Transaction ID already exists."}

  defp find_valid(%{valid?: false} = params, _) do
    [{f, {error, _}}] = params.errors

    field =
      Atom.to_string(f)
      |> String.capitalize()

    {:error, "#{field}: #{error}"}
  end

  def insert_bank_account(%AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    case params["bank_account_id"] do
      nil ->
        Map.put(
          params,
          "bank_account_id",
          Settings.fetch_by_property_id(%ClientSchema{
            name: client_schema,
            attrs: params["property_id"]
          }).default_bank_account_id
        )

      _ ->
        params
    end
  end

  def create_batch(%AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    params = insert_bank_account(%AppCount.Core.ClientSchema{name: client_schema, attrs: params})

    Multi.new()
    |> Multi.insert(:batch, Batch.changeset(%Batch{}, params), prefix: client_schema)
    |> add_batch_items(params["items"], ClientSchema.new(client_schema, params["admin"]))
    |> Repo.transaction()
  end

  def update_batch(id, %AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    Repo.get(Batch, id, prefix: client_schema)
    |> Batch.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def delete_batch(admin, %AppCount.Core.ClientSchema{name: client_schema, attrs: id}) do
    Repo.get(Batch, id, prefix: client_schema)
    |> AppCount.Admins.Utils.Actions.admin_delete(ClientSchema.new(client_schema, admin))
  end

  defp add_batch_items(multi, items, %AppCount.Core.ClientSchema{
         name: client_schema,
         attrs: admin
       }) do
    Multi.run(
      multi,
      :payments,
      fn _, cs ->
        Enum.reduce_while(
          items,
          {:ok, cs},
          fn
            item, {:ok, _} ->
              {:cont,
               add_to_batch(
                 ClientSchema.new(client_schema, cs.batch.id),
                 admin,
                 item
               )}

            _item, {:error, error} ->
              {:halt, {:error, error}}
          end
        )
      end
    )
  end

  defp add_to_batch(
         %AppCount.Core.ClientSchema{name: client_schema, attrs: batch_id},
         admin,
         payment
       ) do
    ClientSchema.new(
      client_schema,
      Map.merge(payment, %{"batch_id" => batch_id, "source" => "admin", "admin" => admin.name})
    )
    |> Payments.create_payment()
  end
end
