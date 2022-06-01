defmodule AppCount.Vendors do
  alias AppCount.Vendors.Utils.Vendors
  alias AppCount.Vendors.Utils.Categories
  alias AppCount.Vendors.Utils.Orders
  alias AppCount.Vendors.Utils.Notes

  # Vendors
  def list_vendors(admin), do: Vendors.list_vendors(admin)
  def create_vendor(params), do: Vendors.create_vendor(params)
  def update_vendor(id, params), do: Vendors.update_vendor(id, params)
  def delete_vendor(id), do: Vendors.delete_vendor(id)

  # Categories
  def list_categories(), do: Categories.list_categories()
  def create_category(params), do: Categories.create_category(params)
  def update_category(id, params), do: Categories.update_category(id, params)
  def delete_category(id), do: Categories.delete_category(id)

  # Skills

  # Orders
  def create_new_order(params), do: Orders.create_new_order(params)
  def list_orders(admin), do: Orders.list_orders(admin)
  def list_orders(admin, id), do: Orders.list_orders(admin, id)
  def get_order(id), do: Orders.get_order(id)
  def create_order(params), do: Orders.create_order(params)
  def create_order(params, m_order), do: Orders.create_order(params, m_order)
  def create_orders(params), do: Orders.create_orders(params)
  def update_order(id, params), do: Orders.update_order(id, params)
  def update_order(params), do: Orders.update_order(params)
  def delete_order(id), do: Orders.delete_order(id)

  # Notes
  def create_note(params), do: Notes.create_note(params)
  def delete_note(id), do: Notes.delete_note(id)
end
