defmodule AppCount.Vendors.Utils.Vendors do
  import Ecto.Query
  import AppCount.EctoExtensions

  alias AppCount.Repo
  alias AppCount.Vendors.Vendor
  alias AppCount.Vendors.Skill
  alias AppCount.Vendors.Property
  alias Ecto.Multi
  require Logger

  def list_vendors(admin) do
    from(
      v in Vendor,
      left_join: c in assoc(v, :categories),
      left_join: p in assoc(v, :properties),
      select: %{
        id: v.id,
        name: v.name,
        email: v.email,
        phone: v.phone,
        address: v.address,
        category_ids: array(c.id),
        categories: jsonize(c, [:id, :name]),
        property_ids: array(p.id),
        properties: array(p.name),
        contact_name: v.contact_name
      },
      where: p.id in ^admin.property_ids and v.active,
      group_by: [v.id],
      order_by: [
        asc: :name
      ]
    )
    |> Repo.all()
  end

  def create_vendor(params) do
    %Vendor{}
    |> Vendor.changeset(params)
    |> Repo.insert()
    |> set_vendor(params)
  end

  def update_vendor(id, params) do
    Repo.get(Vendor, id)
    |> Vendor.changeset(params)
    |> Repo.update()
    |> update_skills_properties(params)
  end

  def update_skills_properties({:ok, vendor}, params) do
    set_vendor_skills(vendor, params)
    set_vendor_properties(vendor, params)
  end

  def delete_vendor(id) do
    Repo.get(Vendor, id)
    |> Repo.delete()
  end

  defp set_vendor({:ok, vendor}, params) do
    set_vendor_skills(vendor, params)
    set_vendor_properties(vendor, params)
  end

  defp set_vendor_skills(vendor, %{"category_ids" => skill_ids}) do
    skill_changes(Multi.new(), vendor, skill_ids)
    |> Repo.transaction()
  end

  defp set_vendor_skills(e, _p), do: Logger.error(inspect(e))

  defp set_vendor_properties(vendor, %{"property_ids" => property_ids}) do
    property_changes(Multi.new(), vendor, property_ids)
    |> Repo.transaction()
  end

  defp skill_changes(multi, vendor, skill_ids) do
    ids = Enum.filter(skill_ids, &is_integer/1)

    to_delete_ids =
      from(
        s in Skill,
        select: s.id,
        where: s.vendor_id == ^vendor.id and s.category_id not in ^ids
      )
      |> Repo.all()

    Enum.reduce(skill_ids, multi, &skill_insert(&1, vendor, &2))
    |> Multi.delete_all(:removed_skills, from(s in Skill, where: s.id in ^to_delete_ids))
  end

  defp property_changes(multi, vendor, property_ids) do
    ids = Enum.filter(property_ids, &is_integer/1)

    to_delete_ids =
      from(
        p in Property,
        select: p.id,
        where: p.vendor_id == ^vendor.id and p.property_id not in ^ids
      )
      |> Repo.all()

    Enum.reduce(property_ids, multi, &property_insert(&1, vendor, &2))
    |> Multi.delete_all(:removed_properties, from(p in Property, where: p.id in ^to_delete_ids))
  end

  defp skill_insert(category_name, vendor, multi) when is_binary(category_name) do
    {:ok, category} = AppCount.Vendors.create_category(%{name: category_name})
    skill_insert(category.id, vendor, multi)
  end

  defp skill_insert(skill_id, vendor, multi) do
    cs = Skill.changeset(%Skill{}, %{vendor_id: vendor.id, category_id: skill_id})
    Multi.insert(multi, "skill_#{skill_id}", cs, on_conflict: :nothing)
  end

  defp property_insert(property_id, vendor, multi) do
    cs = Property.changeset(%Property{}, %{vendor_id: vendor.id, property_id: property_id})
    Multi.insert(multi, "property_#{property_id}", cs, on_conflict: :nothing)
  end
end
