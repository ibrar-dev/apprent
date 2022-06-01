defmodule AppCount.Leases.Utils.Reports do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Leasing.RenewalPeriod
  alias AppCount.Leases.Lease

  def renewal_report(admin, property_id) do
    cond do
      Enum.member?(admin.roles, "Regional") or Enum.member?(admin.roles, "Super Admin") ->
        renewal_report(admin, property_id, :regional)

      true ->
        %{}
    end
  end

  def renewal_report(_admin, property_id, :regional) do
    pending_periods = pending_periods(property_id)
    leases_needing_renewals = leases_needing_renewals(property_id)

    %{
      pending_periods: pending_periods,
      leases_needing_renewals: leases_needing_renewals
    }
  end

  defp pending_periods(property_id) do
    from(
      p in RenewalPeriod,
      where: p.property_id == ^property_id and is_nil(p.approval_date),
      select: count(p.id)
    )
    |> Repo.one()
  end

  defp leases_needing_renewals(property_id) do
    today = AppCount.current_time()

    future_date =
      AppCount.current_time()
      |> Timex.shift(days: 120)

    from(
      l in Lease,
      join: u in assoc(l, :unit),
      where: u.property_id == ^property_id,
      where: l.end_date <= ^future_date and l.end_date >= ^today,
      where: is_nil(l.renewal_package_id) and is_nil(l.renewal_id),
      select: count(l.id),
      limit: 1
    )
    |> Repo.one()
  end

  def most_common_renewal(property_id) do
    from(
      l in Lease,
      join: p in assoc(l, :renewal_package),
      join: u in assoc(l, :unit),
      where: u.property_id == ^property_id,
      select: %{
        id: l.id,
        start_date: l.start_date,
        end_date: l.end_date,
        package: %{
          id: p.id,
          min: p.min,
          max: p.max,
          amount: p.amount,
          dollar: p.dollar
        }
      }
    )
    |> Repo.all()

    #    period_sq = from(
    #      p in RenewalPeriod,
    #      where: p.property_id == ^property_id,
    #      select: p.id
    #    )
    #    package_sq = from(
    #      a in RenewalPackage,
    #      join: p in subquery(period_sq),
    #      on: p == a.renewal_period_id,
    #      select: %{
    #        id: a.id,
    #        min: a.min,
    #        max: a.max,
    #        amount: a.amount,
    #        dollar: a.dollar
    #      }
    #    )
    #    from(
    #      l in Lease,
    #      join: p in subquery(package_sq),
    #      on: p.id == l.renewal_package_id,
    #      select: %{
    #        id: l.id,
    #        start_date: l.start_date,
    #        end_date: l.end_date,
    #        package: %{
    #          id: p.id,
    #          min: p.min,
    #          max: p.max,
    #          amount: p.amount,
    #          dollar: p.dollar
    #        }
    #      },
    #      group_by: [l.id]
    #    )
    #    |> Repo.all
  end

  def get_leases_by_dates(property_id) do
    from(
      l in Lease,
      join: t in assoc(l, :tenants),
      join: u in assoc(l, :unit),
      left_join: c in assoc(l, :charges),
      left_join: cc in assoc(c, :charge_code),
      left_join: cp in assoc(l, :custom_packages),
      select:
        map(
          l,
          [
            :id,
            :start_date,
            :end_date,
            :move_out_date,
            :notice_date,
            :expected_move_in,
            :actual_move_in,
            :actual_move_out,
            :deposit_amount,
            :inserted_at,
            :updated_at
          ]
        ),
      select_merge: %{
        unit: u.number,
        unit_id: u.id,
        charges: jsonize(c, [:id, :amount, {:account, cc.code}]),
        tenants: jsonize(t, [:id, :first_name, :last_name])
      },
      where: u.property_id == ^property_id,
      order_by: [
        desc: :end_date
      ],
      group_by: [l.id, u.id]
    )
  end

  def get_leases(property_id, start_date, end_date) do
    get_leases_by_dates(property_id)
    |> where(
      [l],
      (l.start_date >= ^start_date and l.start_date <= ^end_date) or
        (l.end_date >= ^start_date and l.end_date <= ^end_date) or
        (l.inserted_at >= ^start_date and l.inserted_at <= ^end_date) or
        (l.updated_at >= ^start_date and l.updated_at <= ^end_date)
    )
    |> Repo.all()
  end

  def get_activity_on_leases(property_id, start_date, end_date) do
    get_leases_by_dates(property_id)
    |> where(
      [l],
      (l.inserted_at >= ^start_date and l.inserted_at <= ^end_date) or
        (l.updated_at >= ^start_date and l.updated_at <= ^end_date)
    )
    |> Repo.all()
  end
end
