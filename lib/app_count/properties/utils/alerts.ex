defmodule AppCount.Properties.Utils.Alerts do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Leases.Lease

  def leases_with_no_charges(property_ids) do
    now =
      AppCount.current_time()
      |> Timex.to_date()

    from(
      l in Lease,
      left_join: c in assoc(l, :charges),
      join: u in assoc(l, :unit),
      join: t in assoc(l, :tenants),
      join: p in assoc(u, :property),
      where: u.property_id in ^property_ids,
      where:
        l.start_date <= ^now and is_nil(l.actual_move_out) and
          (l.end_date > ^now or is_nil(l.renewal_id)),
      #      where: u.property_id == 154,
      #      where: l.start_date >= ^today,
      select: %{
        id: l.id,
        start_date: l.start_date,
        end_date: l.end_date,
        expected_move_in: l.expected_move_in,
        actual_move_in: l.actual_move_in,
        property: p.name,
        unit: u.number,
        tenants: jsonize(t, [:id, :last_name]),
        charges: jsonize(c, [:id])
      },
      group_by: [l.id, u.number, p.name]
    )
    |> Repo.all()
    |> Enum.filter(fn l -> Enum.empty?(l.charges) end)
  end

  def past_expected_move_out(property_ids) do
    today = AppCount.current_time()

    from(
      l in Lease,
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      join: t in assoc(l, :tenants),
      where: u.property_id in ^property_ids,
      where: l.move_out_date < ^today and is_nil(l.actual_move_out),
      select: %{
        id: l.id,
        unit: u.number,
        property: p.name,
        move_out_date: l.move_out_date,
        end_date: l.end_date,
        tenants: jsonize(t, [:id, :last_name])
      },
      group_by: [l.id, u.number, p.name]
    )
    |> Repo.all()
  end

  def floorplans_with_no_default_charges(property_ids) do
    from(
      f in AppCount.Properties.FloorPlan,
      left_join: c in assoc(f, :default_charges),
      left_join: u in assoc(f, :units),
      join: p in assoc(u, :property),
      #      where: f.property_id  == 154,
      where: f.property_id in ^property_ids,
      select: %{
        id: f.id,
        units: jsonize(u, [:id, :number]),
        charges: jsonize(c, [:id]),
        name: f.name,
        property: p.name
      },
      group_by: [f.id, p.name]
    )
    |> Repo.all()
    |> Enum.filter(fn f -> Enum.empty?(f.charges) end)
  end
end
