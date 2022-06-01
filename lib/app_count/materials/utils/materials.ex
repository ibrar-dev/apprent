defmodule AppCount.Materials.Utils.Materials do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Materials.Material
  alias AppCount.Materials.Type
  alias AppCount.Materials.Log
  alias AppCount.Materials.Inventory
  alias AppCount.Materials.Utils.Types
  alias AppCount.Materials.Utils.Inventories
  alias AppCount.Core.ClientSchema
  alias Ecto.Multi

  def get_material(id) do
    logs =
      from(
        l in Log,
        join: p in assoc(l, :property),
        select: %{
          id: l.id,
          quantity: l.quantity,
          property_id: l.property_id,
          property: p.name,
          admin: l.admin,
          returned: l.returned,
          material_id: l.material_id,
          inserted_at: l.inserted_at
        }
      )

    from(
      m in Material,
      left_join: l in subquery(logs),
      on: l.material_id == m.id,
      select: %{
        id: m.id,
        name: m.name,
        cost: m.cost,
        image: m.image,
        logs:
          jsonize(
            l,
            [:id, :quantity, :property, :admin, :returned, :inserted_at],
            l.inserted_at,
            "DESC"
          )
      },
      where: m.id == ^id,
      group_by: [m.id]
    )
    |> Repo.one()
  end

  def create_material(params) do
    %Material{}
    |> Material.changeset(params)
    |> Repo.insert()
    |> set_inventory(params)
  end

  def set_inventory({:e, _}), do: nil

  def set_inventory({:ok, mat}, params) do
    Inventories.create_inventory(%{
      stock_id: params["stock_id"],
      material_id: mat.id,
      inventory: params["inventory"]
    })
  end

  def update_material(id, params) do
    mat = Repo.get(Material, id)

    mat
    |> Material.changeset(params)
    |> Repo.update()
    |> update_inventory(params)
  end

  def put_image(id, filename, file_binary) do
    env = AppCount.Config.env()

    AppCount.Utils.put_public_s3(
      "appcount-maintenance:material_images/#{env}/#{id}/#{filename}",
      file_binary
    )
  end

  def update_inventory({:e, _}, _), do: nil

  def update_inventory({:ok, mat}, params) do
    case params["inventory"] do
      nil ->
        nil

      _ ->
        inv =
          from(i in Inventory,
            where: i.material_id == ^mat.id and i.stock_id == ^params["stock_id"],
            select: %{id: i.id, inventory: i.inventory}
          )
          |> Repo.one()

        Inventories.update_inventory(inv.id, %{inventory: params["inventory"]})
    end

    mat
  end

  def delete_material(id) do
    Repo.get(Material, id)
    |> Repo.delete()
  end

  def search_materials(params) do
    inv =
      from(
        i in Inventory,
        join: s in assoc(i, :stock),
        select: %{
          id: i.id,
          stock_id: i.stock_id,
          material_id: i.material_id,
          inventory: i.inventory,
          stock: s.name
        },
        where: i.inventory >= 1
      )

    material_query =
      from(
        m in Material,
        join: i in subquery(inv),
        on: i.material_id == m.id,
        select: %{
          id: m.id,
          name: m.name,
          cost: m.cost,
          type_id: m.type_id,
          per_unit: m.per_unit,
          image: m.image,
          inventory: jsonize(i, [:id, :inventory, :stock, :stock_id])
        },
        group_by: m.id
      )

    types =
      from(
        t in Type,
        join: m in subquery(material_query),
        on: m.type_id == t.id,
        where: ilike(t.name, ^"%#{params}%"),
        select: %{
          id: t.id,
          name: t.name,
          materials: jsonize(m, [:id, :name, :cost, :inventory, :per_unit])
        },
        group_by: t.id
      )
      |> Repo.all()

    materials =
      from(
        m in Material,
        join: t in assoc(m, :type),
        join: i in subquery(inv),
        on: i.material_id == m.id,
        where: ilike(m.name, ^"%#{params}%") or ilike(m.ref_number, ^"%#{params}%"),
        select: %{
          id: m.id,
          name: m.name,
          cost: m.cost,
          per_unit: m.per_unit,
          image: m.image,
          inventory: jsonize(i, [:id, :inventory, :stock, :stock_id])
        },
        group_by: [m.id]
      )
      |> Repo.all()

    %{
      categories: types,
      materials: materials
    }
  end

  def get_ref(%ClientSchema{name: client_schema, attrs: assignment_id}, ref) do
    from(
      m in Material,
      join: s in assoc(m, :stocks),
      join: p in assoc(s, :properties),
      join: u in assoc(p, :units),
      join: o in assoc(u, :orders),
      join: a in assoc(o, :assignments),
      where: a.id == ^assignment_id and m.ref_number == ^ref,
      select: %{
        id: m.id,
        name: m.name
      }
    )
    |> Repo.one(prefix: client_schema)
  end

  def import_csv(path, stock_id) do
    {:ok, signed_url} =
      ExAws.S3.presigned_url(
        ExAws.Config.new(:s3),
        :get,
        "appcount-maintenance",
        "imports/#{path}.csv"
      )

    case HTTPoison.get(signed_url) do
      {:ok, %HTTPoison.Response{body: body}} ->
        body
        |> String.split(~r{\s*\n})
        |> (fn [_first | rest] -> rest end).()
        |> Stream.map(& &1)
        |> CSV.decode()
        |> Enum.to_list()
        |> Enum.reduce(Multi.new(), &import_material(&1, &2, stock_id))
        |> Repo.transaction()

      {:error, error} ->
        {:error, error}
    end
  end

  def import_material({:ok, [ref_number, name, cost, "", _]}, multi, stock_id) do
    import_material({:ok, [ref_number, name, cost, "MISC", nil]}, multi, stock_id)
  end

  def import_material({:ok, [ref_number, name, cost, category_name, _]}, multi, stock_id) do
    if MapSet.member?(multi.names, ref_number) do
      multi
    else
      type_id =
        case Repo.get_by(Type, name: category_name) do
          nil ->
            {:ok, type} = Types.create_material_type(%{"name" => category_name})
            type.id

          type ->
            type.id
        end

      params = %{
        ref_number: ref_number,
        name: name,
        cost: cost,
        type_id: type_id,
        desired: 1,
        stock_id: stock_id
      }

      Multi.insert(multi, ref_number, Material.changeset(%Material{}, params))
    end
  end

  def import_material({:error, error}, multi) do
    Multi.error(multi, :bad_file, error)
  end

  def barcode_data(%Material{} = material) do
    Barlix.Code93.encode!(material.ref_number)
    |> AppCount.Barlix.PNG.data(xdim: 2, height: 120, margin: 10)
    |> Base.encode64()
  end
end
