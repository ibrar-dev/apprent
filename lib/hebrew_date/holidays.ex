defmodule HebrewDate.Holidays do
  @holidays [
    {1, 15},
    {1, 16},
    {1, 21},
    {1, 22},
    {3, 6},
    {3, 7},
    {7, 1},
    {7, 2},
    {7, 10},
    {7, 15},
    {7, 16},
    {7, 22},
    {7, 23}
  ]

  def holiday_dates_for(gregorian_year) do
    {:ok, year_start} = Date.new(gregorian_year, 1, 1)
    collection = []
    holiday_search(gregorian_year, HebrewDate.hebrew_date(year_start), year_start, collection)
  end

  def holiday_search(year_to_search, _, %{year: y}, collection) when y != year_to_search,
    do: collection

  def holiday_search(
        year_to_search,
        %{day: d, month: m} = hebrew_date,
        gregorian_date,
        collection
      ) do
    col =
      if {m, d} in @holidays do
        collection ++ [gregorian_date]
      else
        collection
      end

    holiday_search(
      year_to_search,
      HebrewDate.increment(1, hebrew_date),
      Timex.shift(gregorian_date, days: 1),
      col
    )
  end
end
