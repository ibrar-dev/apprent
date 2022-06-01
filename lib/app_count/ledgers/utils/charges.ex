defmodule AppCount.Ledgers.Utils.Charges do
  alias AppCount.Ledgers.Charge
  alias AppCount.Repo
  alias AppCount.Properties.Unit
  alias AppCount.Leases.Lease
  alias AppCount.Ledgers.CustomerLedger
  alias Ecto.Multi
  use AppCount.Decimal
  import Ecto.Query
  alias AppCount.Core.ClientSchema

  def create_charge(%AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    new_params =
      cond do
        params["post_month"] -> params
        params[:post_month] -> params
        params[:amount] -> Map.put(params, :post_month, post_month())
        params["amount"] -> Map.put(params, "post_month", post_month())
      end

    unless ledger_locked?(
             ClientSchema.new(
               client_schema,
               AppCount.Utils.indifferent(params, :customer_ledger_id)
             )
           ) do
      %Charge{}
      |> Charge.changeset(new_params)
      |> Repo.insert(prefix: client_schema)
    end
  end

  def update_charge(id, %AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    Repo.get(Charge, id, prefix: client_schema)
    |> Charge.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def reverse_charge(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, id, dates) do
    Repo.get(Charge, id, prefix: client_schema)
    |> reverse(dates, ClientSchema.new(client_schema, admin))
  end

  def reverse(%Charge{status: "reversal"} = c, _, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin
      }) do
    AppCount.Admins.Utils.Actions.admin_delete(c, %AppCount.Core.ClientSchema{
      name: client_schema,
      attrs: admin
    })
  end

  def reverse(%Charge{} = c, dates, %AppCount.Core.ClientSchema{name: client_schema, attrs: admin}) do
    Multi.new()
    |> Multi.insert(:reversal, reverse_of(c, dates, admin), prefix: client_schema)
    |> Multi.run(:reversal_id, fn _repo, cs ->
      Charge.changeset(c, %{reversal_id: cs.reversal.id})
      |> Repo.update(prefix: client_schema)
    end)
    |> Repo.transaction()
  end

  def reverse_of(%Charge{amount: a, charge_code_id: charge_code_id, lease_id: l}, dates, admin) do
    p = %{
      amount: Decimal.mult(a, Decimal.new(-1)),
      charge_code_id: charge_code_id,
      bill_date: Timex.parse!(dates.date, "{YYYY}-{M}-{D}"),
      lease_id: l,
      status: "reversal",
      admin: admin.name,
      post_month: Timex.parse!(dates.post_month, "{YYYY}-{M}-{D}")
    }

    %Charge{}
    |> Charge.changeset(p)
  end

  def list_prorate_charges(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: lease_id
        },
        date
      ) do
    date = Timex.to_datetime(Date.from_iso8601!(date))

    from(
      c in AppCount.Ledgers.Charge,
      join: l in assoc(c, :lease),
      join: charge in assoc(c, :charge),
      join: charge_code in assoc(charge, :charge_code),
      join: a in assoc(charge_code, :account),
      where:
        l.id == ^lease_id and c.bill_date >= ^Timex.beginning_of_month(date) and
          a.name != "HAP Rent",
      select:
        map(
          c,
          [
            :account_id,
            :admin,
            :amount,
            :bill_date,
            :charge_id,
            :description,
            :id,
            :lease_id,
            :nsf_id,
            :post_month,
            :reversal_id,
            :status,
            :updated_at
          ]
        ),
      select_merge: %{
        account: a.name,
        inserted_at: type(c.inserted_at, :naive_datetime)
      }
    )
    |> Repo.all(prefix: client_schema)
    |> Enum.map(fn c ->
      start_date =
        if Timex.between?(
             date,
             Timex.beginning_of_month(Timex.to_datetime(c.bill_date)),
             Timex.shift(Timex.end_of_month(c.bill_date), days: 1)
           ) do
          date
        else
          Timex.beginning_of_month(c.bill_date)
        end

      %{
        amount:
          0 -
            Decimal.to_float(c.amount) /
              Timex.days_in_month(c.bill_date) *
              abs(
                Timex.diff(
                  Timex.shift(start_date, days: -1),
                  Timex.end_of_month(c.bill_date),
                  :days
                )
              ),
        charge: c
      }
    end)
  end

  def import_csv(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: property_id},
        %Plug.Upload{content_type: "text/csv", path: path}
      ) do
    {:ok, file_data} = File.read(path)

    AppCount.Utils.parse_csv(file_data)
    |> Enum.reduce(
      0,
      fn
        %{"UnitID" => number} = charge, sum ->
          ClientSchema.new(
            client_schema,
            Repo.get_by(Unit, [number: number, property_id: property_id], prefix: client_schema)
          )
          |> insert_csv_charge(charge)
          |> Kernel.+(sum)

        _, sum ->
          sum
      end
    )
  end

  defp insert_csv_charge(%AppCount.Core.ClientSchema{name: _client_schema, attrs: nil}, _), do: 0

  defp insert_csv_charge(%AppCount.Core.ClientSchema{name: client_schema, attrs: unit}, %{
         "TransactionDate" => date,
         "Comment" => c,
         "Amount" => amount
       }) do
    {:ok, td} = Timex.parse(date, "{M}/{D}/{YYYY}")

    lease_id =
      from(
        l in Lease,
        where: l.unit_id == ^unit.id and l.start_date <= ^td and l.end_date >= ^td,
        select: l.id
      )
      |> Repo.one(prefix: client_schema)

    ClientSchema.new(client_schema, %{
      lease_id: lease_id,
      charge_code_id: charge_code_id(String.replace(c, ~r/ for.*/, "")),
      amount: amount,
      status: "charge",
      bill_date: td
    })
    |> create_charge
    |> import_result
  end

  def import_result({:ok, _}), do: 1
  def import_result(_), do: 0

  def delete_charge(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, id) do
    if MapSet.member?(admin.roles, "Super Admin") do
      Repo.get(Charge, id, prefix: client_schema)
      |> case do
        nil ->
          nil

        c ->
          AppCount.Admins.Utils.Actions.admin_delete(c, ClientSchema.new(client_schema, admin))

          if c.reversal_id do
            Repo.get(Charge, c.reversal_id, prefix: client_schema)
            |> Repo.delete(prefix: client_schema)
          end
      end
    else
      {:error, :unauthorized}
    end
  end

  def clear_charges_by_property(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: admin},
        property_id,
        start_date
      ) do
    from(
      c in Charge,
      join: l in assoc(c, :lease),
      join: u in assoc(l, :unit),
      where: u.property_id == ^property_id and c.bill_date < ^start_date,
      select: c.id
    )
    |> Repo.all(prefix: client_schema)
    |> Enum.each(fn x ->
      delete_charge(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, x)
    end)
  end

  def clear_charges_by_property(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: admin},
        property_id
      ) do
    from(
      c in Charge,
      join: l in assoc(c, :lease),
      join: u in assoc(l, :unit),
      where: u.property_id == ^property_id,
      select: c.id
    )
    |> Repo.all(prefix: client_schema)
    |> Enum.each(fn x ->
      delete_charge(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, x)
    end)
  end

  def create_batch_charges(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: admin},
        %{
          "residents" => residents,
          "note" => note,
          "postDate" => date,
          "postMonth" => pm,
          "charge_code_id" => charge_code_id
        }
      ) do
    bill_date = Timex.parse!(date, "{ISO:Extended:Z}")

    Enum.each(residents, fn r ->
      create_charge(
        ClientSchema.new(client_schema, r),
        note,
        bill_date,
        charge_code_id,
        admin,
        pm
      )
    end)
  end

  def create_batch_charges(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: admin},
        charges,
        params
      ) do
    Enum.map(
      charges,
      fn charge ->
        charge =
          charge
          |> Map.merge(params)
          |> Map.put("admin", admin)

        ClientSchema.new(client_schema, charge)
        |> create_charge
      end
    )
  end

  defp create_charge(
         %AppCount.Core.ClientSchema{name: client_schema, attrs: resident},
         note,
         bill_date,
         charge_code_id,
         admin,
         pm
       ) do
    ClientSchema.new(client_schema, %{
      amount: resident["amount"],
      lease_id: resident["lease_id"],
      description: note,
      admin: admin,
      charge_code_id: charge_code_id,
      status: "manual",
      post_month: pm,
      bill_date: bill_date
    })
    |> create_charge()
  end

  def create_payment(amount, transaction_id, source, tenant_id, property_id) do
    params = %{
      amount: amount,
      transaction_id: transaction_id,
      source: source,
      tenant_id: tenant_id,
      property_id: property_id
    }

    AppCount.Ledgers.Utils.Payments.create_admin_payment(params)
  end

  defp charge_code_id(_name) do
    # temp stand-in
    AppCount.Accounting.SpecialAccounts.get_charge_code(:admin_fees).id

    # TODO this code is almost certainly broken as it was written, will need to revisit this when we come back to this
    #    case Repo.get_by(Account, name: name) do
    #      nil ->
    #        {:ok, t} = Accounting.create_account(%{name: name})
    #        t.id
    #
    #      t ->
    #        t.id
    #    end
  end

  defp post_month(), do: Timex.beginning_of_month(AppCount.current_time())

  # TODO this nil case should never happen, it's here for legacy test stuff only
  def ledger_locked?(%AppCount.Core.ClientSchema{name: _client_schema, attrs: nil}), do: false

  def ledger_locked?(%AppCount.Core.ClientSchema{name: client_schema, attrs: ledger_id}) do
    Repo.one(from(l in CustomerLedger, select: l.closed, where: l.id == ^ledger_id),
      prefix: client_schema
    )
  end
end
