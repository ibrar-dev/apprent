defmodule AppCount.Materials.Utils.Logs do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Materials
  alias AppCount.Materials.Log
  alias AppCount.Materials.Type
  alias AppCount.Materials.Inventory
  alias AppCount.Repo

  def send_materials(%{"quantity" => _} = params, %{"inventory" => _}) do
    %Log{}
    |> Log.changeset(params)
    |> Repo.insert()
    |> subtract_from_inventory
  end

  def list_material_logs(id, start_date, end_date) do
    start_day = Timex.beginning_of_day(start_date)
    end_day = Timex.end_of_day(end_date)

    log_query =
      from(
        l in Log,
        join: p in assoc(l, :property),
        join: s in assoc(l, :stock),
        join: m in assoc(l, :material),
        join: t in assoc(m, :type),
        select: %{
          id: l.id,
          quantity: l.quantity,
          admin: l.admin,
          property: p.name,
          property_id: l.property_id,
          stock: s.name,
          stock_id: l.stock_id,
          material: m.name,
          material_id: l.material_id,
          material_cost: m.cost,
          date: l.inserted_at,
          category: t.name,
          category_id: t.id,
          returned: l.returned
        },
        order_by: [
          desc: l.inserted_at
        ],
        where: l.inserted_at > ^start_day and l.inserted_at < ^end_day and is_nil(l.returned),
        where: l.stock_id == ^id
      )

    from(
      t in Type,
      left_join: l in subquery(log_query),
      on: l.category_id == t.id,
      select: %{
        id: t.id,
        name: t.name,
        logs:
          jsonize(l, [
            :id,
            :quantity,
            :admin,
            :property,
            :property_id,
            :stock,
            :stock_id,
            :material,
            :material_id,
            :date,
            :material_cost,
            :returned
          ])
      },
      group_by: [t.id]
    )
    |> Repo.all()
  end

  def update_material_log(id, params) do
    old_log = Repo.get(Log, id)

    Log.changeset(old_log, params)
    |> Repo.update()
    |> revert_inventory(old_log)
  end

  def revert_inventory({:e, _}), do: nil

  def revert_inventory({:ok, new_log}, old_log) do
    factor =
      cond do
        old_log.returned && !new_log.returned -> -1
        true -> 1
      end

    inv =
      from(
        i in Inventory,
        where: i.stock_id == ^new_log.stock_id and i.material_id == ^new_log.material_id,
        select: %{
          id: i.id,
          inventory: i.inventory
        }
      )
      |> Repo.one()

    Materials.update_inventory(inv.id, %{inventory: inv.inventory + factor * new_log.quantity})
  end

  def subtract_from_inventory({:e, _}), do: nil

  def subtract_from_inventory({:ok, log}) do
    inv =
      from(
        i in Inventory,
        where: i.stock_id == ^log.stock_id and i.material_id == ^log.material_id,
        select: %{
          id: i.id,
          inventory: i.inventory
        }
      )
      |> Repo.one()

    Materials.update_inventory(inv.id, %{inventory: inv.inventory - log.quantity})
    log
  end
end
