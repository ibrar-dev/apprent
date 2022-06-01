defmodule AppCount.Materials.Utils.Stocks do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Materials.Stock
  alias AppCount.Materials.Material
  alias AppCount.Materials.Inventory
  alias AppCount.Materials.Utils.Materials
  alias AppCount.Properties.Property
  alias AppCount.Core.ClientSchema

  def list_stocks(admin) do
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    sq =
      from(
        p in Property,
        select: %{
          stock_id: p.stock_id,
          values: jsonize(p, [:id, :name])
        },
        group_by: p.stock_id,
        where: p.id in ^property_ids
      )

    from(
      s in Stock,
      left_join: m in assoc(s, :materials),
      join: p in subquery(sq),
      on: p.stock_id == s.id,
      select: %{
        id: s.id,
        name: s.name,
        materials: count(m.id),
        properties: p.values,
        image: s.image
      },
      group_by: [s.id, p.values]
    )
    |> Repo.all()
  end

  def print_stock(id) do
    from(
      s in Stock,
      where: s.id == ^id,
      left_join: m in assoc(s, :materials),
      preload: [
        materials: m
      ]
    )
    |> Repo.one()
    |> Map.get(:materials)
    |> Enum.map(fn mat ->
      %{
        name: mat.name,
        ref_number: mat.ref_number,
        code: Materials.barcode_data(mat)
      }
    end)
  end

  def show_stock(id) do
    sq =
      from(
        p in Property,
        select: %{
          stock_id: p.stock_id,
          values: jsonize(p, [:id, :name])
        },
        group_by: p.stock_id
      )

    from(
      s in Stock,
      left_join: m in assoc(s, :materials),
      join: p in subquery(sq),
      on: p.stock_id == s.id,
      select: %{
        id: s.id,
        name: s.name,
        properties: p.values,
        image: s.image,
        materials: count(m.id)
      },
      where: s.id == ^id,
      group_by: [s.id, p.values]
    )
    |> Repo.one()
  end

  def show_stock_materials(id) do
    subquery =
      from(
        i in Inventory,
        where: i.stock_id == ^id,
        select: %{
          id: i.id,
          stock_id: i.stock_id,
          inventory: i.inventory,
          material_id: i.material_id
        }
      )

    from(
      m in Material,
      join: t in assoc(m, :type),
      join: i in subquery(subquery),
      on: i.material_id == m.id,
      #      join: s in assoc(m, :stocks),
      left_join: l in assoc(m, :logs),
      #      where: m.stock_id == ^id,
      select: %{
        id: m.id,
        logs: count(l.id),
        name: m.name,
        cost: m.cost,
        inventory: i.inventory,
        desired: m.desired,
        type_id: m.type_id,
        ref_number: m.ref_number,
        per_unit: m.per_unit,
        type: t.name,
        image: m.image
      },
      group_by: [m.id, i.inventory, t.id],
      order_by: [
        asc: m.name
      ]
    )
    |> Repo.all()
  end

  def create_stock(%{"name" => name, "property_ids" => property_ids}) do
    {:ok, stock} =
      %Stock{}
      |> Stock.changeset(%{name: name})
      |> Repo.insert(
        on_conflict: [
          set: [
            name: name
          ]
        ],
        conflict_target: :name
      )

    property_ids
    |> Enum.each(fn id ->
      Repo.get(Property, id)
      |> Property.changeset(%{stock_id: stock.id})
      |> Repo.update()
    end)
  end

  def update_stock(id, %{"property_ids" => ids} = params) when is_list(ids) and length(ids) > 0 do
    from(p in Property, where: p.stock_id == ^id)
    |> Repo.update_all(
      set: [
        stock_id: nil
      ]
    )

    ids
    |> Enum.each(fn prop_id ->
      Repo.get(Property, prop_id)
      |> Property.changeset(%{stock_id: id})
      |> Repo.update()
    end)

    update_stock(id, Map.delete(params, "property_ids"))
  end

  def update_stock(id, params) do
    Repo.get(Stock, id)
    |> Stock.changeset(params)
    |> Repo.update()
  end

  def put_image(id, filename, file_binary) do
    env = AppCount.Config.env()

    AppCount.Utils.put_public_s3(
      "appcount-maintenance:stock_images/#{env}/#{id}/#{filename}",
      file_binary
    )
  end

  def delete_stock(id) do
    Repo.get(Stock, id)
    |> Repo.delete()
  end

  def assignment_inventory(id) do
    from(
      m in Material,
      join: s in assoc(m, :stocks),
      join: p in assoc(s, :properties),
      join: u in assoc(p, :units),
      join: o in assoc(u, :orders),
      join: a in assoc(o, :assignments),
      where: a.id == ^id,
      select: %{
        id: m.id,
        name: m.name,
        inventory: m.inventory
      }
    )
    |> Repo.all()
  end

  def property_inventory(property_id) do
    from(
      m in Material,
      join: s in assoc(m, :stocks),
      join: p in assoc(s, :properties),
      where: p.id == ^property_id,
      select: %{
        id: m.id,
        name: m.name,
        inventory: m.inventory
      }
    )
    |> Repo.all()
  end

  def duplicate_stock_materials(initial_stock_id, destination_stock_id) do
    from(
      m in Material,
      where: m.stock_id == ^initial_stock_id,
      select: %{
        id: m.id,
        name: m.name,
        cost: m.cost,
        type_id: m.type_id,
        ref_number: m.ref_number,
        per_unit: m.per_unit
      }
    )
    |> Repo.all()
    |> Enum.each(fn m ->
      Map.put(m, :stock_id, destination_stock_id) |> Materials.create_material()
    end)
  end
end
