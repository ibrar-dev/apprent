defmodule AppCount.Reports.Queries do
  alias AppCount.Reports.Queries.EffectiveRent
  alias AppCount.Reports.Queries.MarketRent
  alias AppCount.Reports.Queries.Vacancy
  alias AppCount.Reports.Queries.UnitStatus

  def effective_rent(property_id, date), do: EffectiveRent.effective_rent(property_id, date)

  def market_rent(property_id, date), do: MarketRent.market_rent_query(property_id, date)
  def rent_charge_query(date), do: MarketRent.rent_charge_query(date)

  def vacancy(property_id, start_date, end_date),
    do: Vacancy.vacancy_query(property_id, start_date, end_date)

  def unit_status(property_id, date), do: UnitStatus.get_status(property_id, date)
  def full_unit_status(property_id, date), do: UnitStatus.full_unit_status(property_id, date)
end
