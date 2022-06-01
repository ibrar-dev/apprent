defmodule AppCount.Prospects do
  alias AppCount.Prospects.Utils.Showings
  alias AppCount.Prospects.Utils.Openings
  alias AppCount.Prospects.Utils.TrafficSources
  alias AppCount.Prospects.Utils.Prospects
  alias AppCount.Prospects.Utils.Memos
  alias AppCount.Prospects.Utils.Closures
  alias AppCount.Prospects.Utils.Referrals

  # Prospects
  def list_prospects(admin), do: Prospects.list_prospects(admin)
  def create_prospect(params), do: Prospects.create_prospect(params)
  def update_prospect(id, params), do: Prospects.update_prospect(id, params)
  def delete_prospect(id), do: Prospects.delete_prospect(id)

  # Closures
  def list_closures(property_id), do: Closures.list_closures(property_id)
  def create_closure(params), do: Closures.create_closure(params)
  def create_closure(params, type), do: Closures.create_closure(params, type)
  def update_closure(id, params), do: Closures.update_closure(id, params)
  def delete_closures(id), do: Closures.delete_closure(id)

  def list_affected_showings(property_id, date),
    do: Closures.list_affected_showings(property_id, date)

  # Memos
  def list_memos(admin), do: Memos.list_memos(admin)
  def create_memo(params), do: Memos.create_memo(params)

  # Showings
  def list_showings(admin), do: Showings.list_showings(admin)
  def create_showing(params), do: Showings.create_showing(params)
  def update_showing(id, params), do: Showings.update_showing(id, params)
  def delete_showing(id), do: Showings.delete_showing(id)

  # Openings
  def list_available(property_id), do: Openings.list_available(property_id)
  def list_openings(admin), do: Openings.list_openings(admin)
  def create_opening(params), do: Openings.create_opening(params)
  def update_opening(id, params), do: Openings.update_opening(id, params)
  def delete_opening(id), do: Openings.delete_opening(id)

  # Traffic Sources
  def list_traffic_sources(), do: TrafficSources.list_traffic_sources()
  def create_traffic_source(params), do: TrafficSources.create_traffic_source(params)
  def update_traffic_source(id, params), do: TrafficSources.update_traffic_source(id, params)
  def delete_traffic_source(id), do: TrafficSources.delete_traffic_source(id)

  # Referrals
  def record_referral(conn), do: Referrals.record_referral(conn)
end
