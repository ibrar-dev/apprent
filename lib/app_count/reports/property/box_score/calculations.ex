defmodule AppCount.Reports.BoxScore.Calculations do
  use AppCount.Decimal

  def get_calculations(unit_count, %{
        down: down,
        model: model,
        notice_rented: nr,
        notice_unrented: nur,
        occupied: occ,
        vacant_rented: vr
      }) do
    %{
      occ: occupancy(unit_count, occ.count, nr.count + nur.count),
      occ_non_rev:
        occupancy_no_rev(unit_count, occ.count, model.count, down.count, nr.count + nur.count),
      leased: leased(unit_count, occ.count, vr.count),
      trend: trend(unit_count, occ.count, nr.count)
    }
  end

  # Total number of units + Notice
  def occupancy(0, _, _), do: 0.00

  def occupancy(units, occupied, notice) do
    ((occupied + notice) / units * 100)
    |> round_percentage
  end

  # Occupied + Model + Down + Admin
  def occupancy_no_rev(0, _, _, _, _), do: 0.00

  def occupancy_no_rev(units, occupied, model, down, notice) do
    ((occupied + model + down + notice) / units * 100)
    |> round_percentage
  end

  # Occupied + Vacant Rented(Preleased)
  def leased(0, _, _), do: 0.00

  def leased(units, occupied, vr) do
    ((occupied + vr) / units * 100)
    |> round_percentage
  end

  # Occupied - Notice
  def trend(0, _, _), do: 0.00

  def trend(units, occupied, notice) do
    ((occupied - notice) / units * 100)
    |> round_percentage
  end

  def round_percentage(float) when is_integer(float), do: round_percentage(Decimal.new(float))

  def round_percentage(float) when is_float(float),
    do: round_percentage(Decimal.from_float(float))

  def round_percentage(float) do
    float
    |> Decimal.round(2)
  end
end
