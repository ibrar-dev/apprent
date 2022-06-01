defmodule AppCount.Maintenance.Utils.Queries do
  alias AppCount.Maintenance.Utils.Queries.Orders
  alias AppCount.Maintenance.Utils.Queries.ShowOrder
  alias AppCount.Maintenance.Utils.Queries.Analytics
  alias AppCount.Core.ClientSchema

  def list_orders(admin, dates, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_id
      }),
      do: Orders.list_orders(admin, dates, ClientSchema.new(client_schema, property_id))

  def list_orders_type(property_id, type), do: Orders.list_orders_type(property_id, type)
  def show_order(admin, id), do: ShowOrder.show_order(admin, id)

  def get_analytics(dates, property_ids, type),
    do: Analytics.get_analytics(dates, property_ids, type)
end
