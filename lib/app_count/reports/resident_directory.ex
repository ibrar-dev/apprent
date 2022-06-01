defmodule AppCount.Reports.ResidentDirectory do
  alias AppCount.Repo
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Ledgers.Utils.SpecialChargeCodes
  alias AppCount.Tenants.Tenancy

  def rent_charge_query(date) do
    rent_cc = SpecialChargeCodes.get_charge_code(:rent)
    haprent_cc = SpecialChargeCodes.get_charge_code(:hap_rent)

    from(
      c in AppCount.Leasing.Charge,
      where:
        (c.from_date <= ^date and is_nil(c.to_date)) or
          (is_nil(c.from_date) and c.to_date >= ^date) or
          (is_nil(c.from_date) and is_nil(c.to_date)) or
          (c.from_date <= ^date and c.to_date >= ^date),
      join: a in assoc(c, :account),
      where: c.charge_code_id == ^rent_cc.id or c.charge_code_id == ^haprent_cc.id,
      select: %{
        id: c.id,
        amount: c.amount,
        lease_id: c.lease_id,
        name: a.name
      }
    )
  end

  def resident_directory(property_id) do
    curr_date = AppCount.current_date()

    AppCount.Leasing.LeaseRepo.most_current_lease_query(property_id)
    |> join(:inner, [l], t in Tenancy, on: t.customer_ledger_id == l.customer_ledger_id)
    |> join(:left, [l], c in subquery(rent_charge_query(curr_date)), on: c.lease_id == l.id)
    |> join(:left, [l, t], u in assoc(t, :unit))
    |> join(:left, [l, t], te in assoc(t, :tenant))
    #    |> join(:left, [l], f in assoc(l, :form))
    |> select_merge(
      [l, tenancy, c, u, t, f],
      %{
        lease: map(l, [:id, :start_date, :end_date]),
        tenancy:
          jsonize(tenancy, [
            :id,
            :actual_move_in,
            :actual_move_out,
            :start_date,
            :eviction_file_date,
            :eviction_court_date
          ]),
        rent: sum(c.amount),
        unit: map(u, [:id, :number]),
        tenants: jsonize(t, [:id, :first_name, :last_name, :email])
        #        deposit: f.deposit_value
      }
    )
    |> group_by([l, _c, u, t], [
      l.id,
      u.id
      #      f.id,
    ])
    |> Repo.all()
  end
end
