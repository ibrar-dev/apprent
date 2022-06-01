defmodule AppCount.Materials.Utils.ToolboxItems do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Materials.ToolboxItem
  alias AppCount.Materials.Material
  alias AppCount.Materials.Inventory
  alias AppCount.Materials.Type
  alias AppCount.Materials
  alias AppCount.Maintenance.Tech
  alias AppCount.Maintenance.Assignment
  alias AppCount.Core.ClientSchema
  alias AppCount.Repo
  require Logger

  def list_moved_items(start_date, end_date) do
    item_query =
      from(
        t in ToolboxItem,
        select: %{
          id: t.id,
          stock_id: t.stock_id,
          material_id: t.material_id,
          status: t.status,
          tech_id: t.tech_id,
          updated_at: t.updated_at
        },
        where:
          t.updated_at >= ^start_date and t.updated_at <= ^end_date and
            t.stock_id != t.return_stock and
            (t.status == "ordered" or t.status == "returned")
      )

    from(
      m in Material,
      join: i in subquery(item_query),
      on: m.id == i.material_id,
      join: t in assoc(m, :type),
      select: %{
        id: i.id,
        stock_id: i.stock_id,
        material_id: i.material_id,
        status: i.status,
        tech_id: i.tech_id,
        updated_at: i.updated_at,
        name: m.name,
        type_name: t.name,
        type_id: m.type_id
      },
      order_by: m.type_id
    )
    |> Repo.all()
  end

  def list_possible_items(stock_id) do
    inv_query =
      from(
        i in Inventory,
        select: %{
          id: i.id,
          stock_id: i.stock_id,
          material_id: i.material_id,
          inventory: i.inventory
        }
      )

    from(
      m in Material,
      join: i in subquery(inv_query),
      on: m.id == i.material_id,
      join: t in assoc(m, :type),
      where: i.stock_id == ^stock_id and i.inventory > 0,
      select: %{
        id: m.id,
        name: m.name,
        inventory: i.inventory,
        type: t.name,
        image: m.image,
        cost: m.cost
      },
      order_by: m.name
    )
    |> Repo.all()
  end

  def list_ordered_items(stock_id, start_date, end_date) do
    start_day = Timex.beginning_of_day(start_date)
    end_day = Timex.end_of_day(end_date)

    property_query =
      from(
        p in AppCount.Properties.Property,
        select: %{
          id: p.id,
          name: p.name,
          stock_id: p.stock_id
        }
      )

    ordered_query =
      from(
        t in ToolboxItem,
        join: m in assoc(t, :material),
        join: s in assoc(t, :stock),
        join: p in subquery(property_query),
        on: p.stock_id == t.stock_id,
        where: t.status == "ordered" and between(t.inserted_at, ^start_day, ^end_day),
        where: t.stock_id == ^stock_id,
        select: %{
          id: t.id,
          property: p.name,
          property_id: p.id,
          stock: s.name,
          stock_id: t.stock_id,
          material: m.name,
          date: t.updated_at,
          material_cost: m.cost,
          material_id: t.material_id,
          type_id: m.type_id
        },
        order_by: [
          desc: t.updated_at
        ]
      )

    from(
      t in Type,
      left_join: l in subquery(ordered_query),
      on: l.type_id == t.id,
      select: %{
        id: t.id,
        name: t.name,
        logs:
          jsonize(l, [
            :id,
            :property,
            :property_id,
            :stock,
            :stock_id,
            :material,
            :material_cost,
            :date,
            :material_id,
            {:quantity, 1}
          ])
      },
      group_by: [t.id]
    )
    |> Repo.all()
  end

  def list_items_in_cart(tech_id, stock_id) do
    inventory_query =
      from(
        i in Inventory,
        where: i.stock_id == ^stock_id,
        select: %{
          id: i.id,
          material_id: i.material_id,
          inventory: i.inventory
        }
      )

    from(
      i in ToolboxItem,
      join: m in assoc(i, :material),
      join: inv in subquery(inventory_query),
      on: i.material_id == inv.material_id,
      select: %{
        id: i.id,
        name: m.name,
        inventory: inv.inventory,
        material_id: inv.material_id
      },
      where: i.tech_id == ^tech_id and i.stock_id == ^stock_id and i.status == "pending"
    )
    |> Repo.all()
  end

  def list_items_in_toolbox(%ClientSchema{name: client_schema, attrs: tech_id}) do
    item_query =
      from(
        i in ToolboxItem,
        join: s in assoc(i, :stock),
        join: m in assoc(i, :material),
        select: %{
          id: i.id,
          tech_id: i.tech_id,
          stock_id: i.stock_id,
          material_id: i.material_id,
          stock: s.name,
          material: m.name,
          image: m.image,
          date: i.inserted_at
        },
        where: i.tech_id == ^tech_id and i.status == "checked_out",
        group_by: [i.tech_id, m.id, s.id, i.id]
      )

    from(
      t in Tech,
      join: i in subquery(item_query),
      on: i.tech_id == t.id,
      select: %{
        id: t.id,
        name: t.name,
        items: jsonize(i, [:id, :stock_id, :material_id, :stock, :material, :date, :image])
      },
      group_by: [t.id]
    )
    |> Repo.all(prefix: client_schema)
  end

  def list_all_items() do
    from(
      i in ToolboxItem,
      join: s in assoc(i, :stock),
      join: m in assoc(i, :material),
      select: %{
        id: i.id,
        stock: s.name,
        stock_id: i.stock_id,
        material: m.name,
        material_id: i.material_id,
        admin: i.admin,
        status: i.status,
        history: i.history,
        tech_id: i.tech_id,
        cost: m.cost,
        per_unit: m.per_unit,
        inserted_at: i.inserted_at,
        image: m.image
      },
      order_by: [
        desc: i.inserted_at
      ]
    )
  end

  def admin_add(params, admin) do
    new_params = Map.merge(params, %{"admin" => admin, "status" => "ordered"})

    %ToolboxItem{}
    |> ToolboxItem.changeset(new_params)
    |> Repo.insert()
    |> subtract_from_inventory
    |> admin_attach_item_to_assignment(params["assignment_id"])
  end

  def admin_add_toolbox(%{"tech_id" => tech_id} = params, admin) do
    new_params = Map.merge(params, %{"admin" => admin, "status" => "checked_out"})

    %ToolboxItem{}
    |> ToolboxItem.changeset(new_params)
    |> Repo.insert()
    |> subtract_from_inventory
    |> notify_tech(tech_id)
  end

  def add_item_to_toolbox(params) do
    %ToolboxItem{}
    |> ToolboxItem.changeset(params)
    |> Repo.insert!()
  end

  def notify_tech(_, tech_id) do
    # FIX_DEPS
    AppCountWeb.TechChannel.send_toolbox(tech_id)
  end

  def notify_tech({:ok, item}) do
    AppCountWeb.TechChannel.send_toolbox(item.tech_id)
  end

  def notify_tech({:error, _}), do: nil

  def notify_tech(tech_id) do
    AppCountWeb.TechChannel.send_toolbox(tech_id)
  end

  def checkout_items_in_toolbox(tech_id, stock_id) do
    from(
      i in ToolboxItem,
      where: i.tech_id == ^tech_id and i.stock_id == ^stock_id and i.status == "pending",
      select: i.id
    )
    |> Repo.all()
    |> Enum.each(fn x -> change_status(x, "checked_out") |> subtract_from_inventory end)
    |> notify_tech(tech_id)
  end

  def order_item(id) do
    change_status(id, "ordered")
  end

  #  def return_item_to_stock(id) do
  #    change_status(id, "returned")
  #    |> add_back_to_inventory
  #  end

  def return_item_from_cart(id) do
    change_status(id, "returned")
  end

  def return_item_to_stock(id, stock_id) do
    change_status(id, "returned")
    |> return_to_different_stock(stock_id)
    |> add_back_to_inventory(stock_id)
  end

  def return_to_different_stock({:ok, item}, stock_id) do
    item
    |> ToolboxItem.changeset(%{return_stock: stock_id})
    |> Repo.update()
  end

  def add_back_to_inventory({:error, _}, _), do: nil

  def add_back_to_inventory({:ok, item}, stock_id) do
    inv =
      from(
        i in Inventory,
        where: i.stock_id == ^stock_id and i.material_id == ^item.material_id,
        select: %{
          id: i.id,
          inventory: i.inventory
        }
      )
      |> Repo.one()

    Materials.update_inventory(inv.id, %{inventory: inv.inventory + 1})
  end

  def change_status(id, status) do
    history =
      from(
        i in ToolboxItem,
        where: i.id == ^id,
        select: i.history
      )
      |> Repo.one()

    new_history =
      [%{change: status, time: AppCount.current_time()}]
      |> Enum.concat(history || [])

    Repo.get(ToolboxItem, id)
    |> ToolboxItem.changeset(%{status: status, history: new_history})
    |> Repo.update()
  end

  def add_back_to_inventory({:error, _item}) do
  end

  def add_back_to_inventory({:ok, item}) do
    inv =
      from(
        i in Inventory,
        where: i.stock_id == ^item.stock_id and i.material_id == ^item.material_id,
        select: %{
          id: i.id,
          inventory: i.inventory
        }
      )
      |> Repo.one()

    Materials.update_inventory(inv.id, %{inventory: inv.inventory + 1})
  end

  def subtract_from_inventory({:error, _item}) do
    Logger.error("subtracting from inventory 2")
  end

  def subtract_from_inventory({:ok, item}) do
    inv =
      from(
        i in Inventory,
        where: i.stock_id == ^item.stock_id and i.material_id == ^item.material_id,
        select: %{
          id: i.id,
          inventory: i.inventory
        }
      )
      |> Repo.one()

    Materials.update_inventory(inv.id, %{inventory: inv.inventory - 1})
  end

  def clear_pending_toolbox(tech_id) do
    from(
      i in ToolboxItem,
      where: i.tech_id == ^tech_id and i.status == "pending",
      select: i.id
    )
    |> Repo.all()
    |> Enum.each(fn id -> remove_item_from_toolbox(id) end)
  end

  def remove_item_from_toolbox(id) do
    Repo.get(ToolboxItem, id)
    |> Repo.delete()
  end

  def attach_items_to_assignment(%ClientSchema{
        name: client_schema,
        attrs: %{"inventory" => params}
      }) do
    params
    |> Enum.each(fn i ->
      attach_item_to_assignment(client_schema, i["id"], i["assignment_id"])
    end)
  end

  def list_toolbox_items_movement(_start_date, _end_date) do
    #    start_day = Timex.beginning_of_day(start_date)
    #    end_day = Timex.end_of_day(end_date)
    #    changed_query = from(
    #      t in ToolboxItem,
    ##      join:
    #      where: t.status == "returned" and not is_nil(t.return_stock),
    #      where: between(t.updated_at, ^start_day, ^end_day),
    #      select: %{
    #        id: t.id,
    #
    #      }
    #    )
    #    from(
    #      t in ToolboxItem,
    #      where: t.status == "ordered"
    #    )
  end

  defp admin_attach_item_to_assignment(toolbox_item, assignment_id) do
    assignment = Repo.get(Assignment, assignment_id)

    {name, cost, per_unit, id} =
      from(
        m in Material,
        where: m.id == ^toolbox_item.material_id,
        select: {
          m.name,
          m.cost,
          m.per_unit,
          m.id
        }
      )
      |> Repo.one()

    mat = [
      %{
        num: 1,
        cost: Decimal.to_float(Decimal.div(cost, per_unit)),
        name: name,
        material_id: id,
        toolbox_item_id: toolbox_item.id
      }
      | assignment.materials
    ]

    Assignment.changeset(assignment, %{materials: mat})
    |> Repo.update()

    toolbox_item
  end

  defp attach_item_to_assignment(client_schema, toolbox_item_id, assignment_id) do
    toolbox_item = Repo.get(ToolboxItem, toolbox_item_id, prefix: client_schema)
    assignment = Repo.get(Assignment, assignment_id, prefix: client_schema)

    {name, cost, per_unit, id} =
      from(
        m in Material,
        where: m.id == ^toolbox_item.material_id,
        select: {
          m.name,
          m.cost,
          m.per_unit,
          m.id
        }
      )
      |> Repo.one(prefix: client_schema)

    mat = [
      %{
        num: 1,
        cost: Decimal.to_float(Decimal.div(cost, per_unit)),
        name: name,
        material_id: id,
        toolbox_item_id: toolbox_item_id
      }
      | assignment.materials
    ]

    Assignment.changeset(assignment, %{materials: mat})
    |> Repo.update(prefix: client_schema)

    order_item(toolbox_item_id)
  end

  # auth tech
  def authenticate_tech(identifier) do
    from(
      t in Tech,
      where: t.identifier == ^identifier,
      select: %{
        id: t.id,
        email: t.email,
        name: t.name,
        image: t.image
      }
    )
    |> Repo.one()
  end
end
