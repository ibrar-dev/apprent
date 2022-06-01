defmodule AppCount.Reports.Property.BoxScore do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Properties.FloorPlan

  alias AppCount.Reports.Property.BoxScore.Availability
  alias AppCount.Reports.Property.BoxScore.ResidentActivity
  alias AppCount.Reports.Property.BoxScore.FirstContact

  alias AppCount.Properties.Utils.Calculations

  def box_score(property_id, dates, "availability") do
    date =
      String.split(dates, ",")
      |> List.last()
      |> Date.from_iso8601!()

    %{
      floor_plans: box_score_fp_avail(property_id, date),
      property_calculations: Calculations.property_calculations(property_id, date)
    }
  end

  def box_score(property_id, dates, "residentActivity") do
    start_d =
      String.split(dates, ",")
      |> List.first()
      |> Date.from_iso8601!()

    end_d =
      String.split(dates, ",")
      |> List.last()
      |> Date.from_iso8601!()

    box_score_fp_ra(property_id, start_d, end_d)
  end

  def box_score(property_id, dates, "firstContact") do
    start_date =
      String.split(dates, ",")
      |> List.first()
      |> Timex.parse!("{YYYY}-{M}-{D}")

    end_date =
      String.split(dates, ",")
      |> List.last()
      |> Timex.parse!("{YYYY}-{M}-{D}")
      |> Timex.end_of_day()

    FirstContact.get_payments_with_description(property_id, start_date, end_date)
  end

  def box_score_fp_avail(property_id, date) do
    from(
      fp in FloorPlan,
      where: fp.property_id == ^property_id,
      select: fp.id
    )
    |> Repo.all()
    |> Enum.map(&Availability.floor_plan(&1, date))
  end

  def box_score_fp_ra(property_id, start_date, end_date) do
    from(
      fp in FloorPlan,
      where: fp.property_id == ^property_id,
      select: fp.id
    )
    |> Repo.all()
    |> Enum.map(&ResidentActivity.floor_plan(&1, start_date, end_date))
  end
end
