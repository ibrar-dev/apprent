defmodule AppCount.Maintenance.Utils.Public do
  alias AppCount.Maintenance.Utils.Public.Orders

  def get_order(uuid, type), do: Orders.get_order(uuid, type)
end
