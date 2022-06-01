defmodule AppCount.Units do
  alias AppCount.Units.Utils.MarketRents
  alias AppCount.Units.Utils.DefaultLeaseCharges

  def market_rent(unit_id), do: MarketRents.market_rent(unit_id)

  #  def upload_market_rents_csv(admin, params), do: MarketRents.upload_market_rents_csv(admin, params)

  def create_default_charge(params), do: DefaultLeaseCharges.create_default_charge(params)

  def multi_create_default_charges(params),
    do: DefaultLeaseCharges.multi_create_default_charges(params)

  def update_default_charge(id, params), do: DefaultLeaseCharges.update_default_charge(id, params)
  def update_default_charges(params), do: DefaultLeaseCharges.update_default_charges(params)
  def delete_default_charge(id), do: DefaultLeaseCharges.delete_default_charge(id)
  def default_charges(unit_id), do: DefaultLeaseCharges.default_charges(unit_id)

  def clone_charges(initial_id, target_id),
    do: DefaultLeaseCharges.clone_charges(initial_id, target_id)
end
