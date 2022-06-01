defmodule AppCount.Materials do
  alias AppCount.Materials.Utils.Materials
  alias AppCount.Materials.Utils.Types
  alias AppCount.Materials.Utils.Logs
  alias AppCount.Materials.Utils.Stocks
  alias AppCount.Materials.Utils.Orders
  alias AppCount.Materials.Utils.OrderItems
  alias AppCount.Materials.Utils.ToolboxItems
  alias AppCount.Materials.Utils.Inventories
  alias AppCount.Materials.Utils.Warehouses

  ## Materials

  def get_material(id), do: Materials.get_material(id)
  def create_material(params), do: Materials.create_material(params)
  def update_material(id, params), do: Materials.update_material(id, params)
  def delete_material(id), do: Materials.delete_material(id)
  def get_ref(assignment_id, ref), do: Materials.get_ref(assignment_id, ref)
  def import_csv(path, stock_id), do: Materials.import_csv(path, stock_id)
  def barcode_data(material), do: Materials.barcode_data(material)
  def search_materials(params), do: Materials.search_materials(params)

  ## Material Types

  def list_material_types(), do: Types.list_material_types()
  def create_material_type(params), do: Types.create_material_type(params)
  def update_material_type(id, params), do: Types.update_material_type(id, params)
  def delete_material_type(id), do: Types.delete_material_type(id)

  ## Material Logs

  def send_materials(params, material), do: Logs.send_materials(params, material)

  def list_material_logs(id, start_date, end_date),
    do: Logs.list_material_logs(id, start_date, end_date)

  def update_material_log(id, params), do: Logs.update_material_log(id, params)

  ## Stocks

  def list_stocks(admin), do: Stocks.list_stocks(admin)
  def print_stock(id), do: Stocks.print_stock(id)
  def create_stock(params), do: Stocks.create_stock(params)
  def update_stock(id, params), do: Stocks.update_stock(id, params)
  def delete_stock(id), do: Stocks.delete_stock(id)
  def property_inventory(property_id), do: Stocks.property_inventory(property_id)
  def assignment_inventory(assignment_id), do: Stocks.assignment_inventory(assignment_id)
  def show_stock(id), do: Stocks.show_stock(id)
  def show_stock_materials(id), do: Stocks.show_stock_materials(id)

  ## Orders

  def create_materials_order(params), do: Orders.create_order(params)
  def update_materials_order(id, params), do: Orders.update_order(id, params)
  #  def delete_order(id, params), do: MaterialOrders.delete_order(id, params)

  ## MaterialsOrderItems
  def list_materials_order_items(id), do: OrderItems.list_items_in_cart(id)
  def create_materials_order_item(params), do: OrderItems.create_item(params)
  def update_materials_order_item(id, params), do: OrderItems.update_item(id, params)

  ## ToolboxItems
  #  def list_all_used_or_returned_items(start_date, end_date), do: ToolBoxItems.list_all_used_or_returned_items(start_date, end_date)
  def add_item_to_toolbox(params), do: ToolboxItems.add_item_to_toolbox(params)

  def list_items_in_cart(tech_id, stock_id),
    do: ToolboxItems.list_items_in_cart(tech_id, stock_id)

  def list_items_in_toolbox(tech_id), do: ToolboxItems.list_items_in_toolbox(tech_id)

  def checkout_items_in_toolbox(tech_id, stock_id),
    do: ToolboxItems.checkout_items_in_toolbox(tech_id, stock_id)

  def list_ordered_items(stock_id, start_date, end_date),
    do: ToolboxItems.list_ordered_items(stock_id, start_date, end_date)

  #  def return_item_to_stock(id), do: ToolboxItems.return_item_to_stock(id)
  def return_item_from_cart(id), do: ToolboxItems.return_item_from_cart(id)
  def return_item_to_stock(id, stock_id), do: ToolboxItems.return_item_to_stock(id, stock_id)
  def clear_pending_toolbox(tech_id), do: ToolboxItems.clear_pending_toolbox(tech_id)
  def remove_item_from_toolbox(id), do: ToolboxItems.remove_item_from_toolbox(id)
  def authenticate_tech(param), do: ToolboxItems.authenticate_tech(param)
  def list_possible_items(stock_id), do: ToolboxItems.list_possible_items(stock_id)
  def attach_items_to_assignment(params), do: ToolboxItems.attach_items_to_assignment(params)
  def admin_add(params, admin), do: ToolboxItems.admin_add(params, admin)
  def admin_add_toolbox(params, admin), do: ToolboxItems.admin_add_toolbox(params, admin)

  def list_toolbox_items_movement(start_date, end_date),
    do: ToolboxItems.list_toolbox_items_movement(start_date, end_date)

  ## Inventories
  def create_inventory(params), do: Inventories.create_inventory(params)
  def update_inventory(id, params), do: Inventories.update_inventory(id, params)

  ## Warehouses
  def create_warehouse(params), do: Warehouses.create_warehouse(params)
  def update_warehouse(id, params), do: Warehouses.update_warehouse(id, params)
end
