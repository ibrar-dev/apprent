defmodule AppCount.Reports.Queries.Vacancy do
  import Ecto.Query

  def vacancy_query(property_id, start_date, end_date) when is_binary(start_date) do
    vacancy_query(property_id, Date.from_iso8601!(start_date), Date.from_iso8601!(end_date))
  end

  def vacancy_query(property_id, start_date, end_date) do
    fake_start = Timex.shift(start_date, days: -1)

    from(
      u in subquery(AppCount.Tenants.TenancyRepo.property_tenancies_query(property_id)),
      select: %{
        days_vacant:
          fragment(
            "? - sum(coalesce(UPPER(daterange(?, ?) * daterange(?, ?)) - LOWER(daterange(?, ?) * daterange(?, ?)), 0))",
            ^Timex.diff(end_date, fake_start, :days),
            ^fake_start,
            ^end_date,
            u.start_date - 1,
            u.actual_move_out,
            ^fake_start,
            ^end_date,
            u.start_date - 1,
            u.actual_move_out
          ),
        unit_id: u.unit_id
      },
      group_by: u.unit_id
    )
  end
end
