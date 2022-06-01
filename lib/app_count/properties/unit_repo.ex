defmodule AppCount.Properties.UnitRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Properties.Unit,
    preloads: [tenancies: [tenant: []], property: [logo_url: [], icon_url: []]]

  def navbar_search(property_ids, term) do
    from(
      u in @schema,
      where: u.property_id in ^property_ids,
      where: ilike(u.number, ^"%#{term}%"),
      preload: ^@preloads
    )
    |> Repo.all()
    |> Enum.map(&sort_and_map(&1))
  end

  # needed: unit number, property name, tenancy_id, tenant name
  defp sort_and_map(unit) do
    tenancy =
      case length(unit.tenancies) do
        0 -> nil
        _ -> List.first(unit.tenancies)
      end

    %{
      type: "units",
      unit: unit.number,
      property: unit.property.name,
      id: unit.id,
      icon: icon_url(unit.property.icon_url),
      name: nil,
      tenancy_id: nil
    }
    |> tenancy_data(tenancy)
  end

  defp tenancy_data(map, nil), do: map

  defp tenancy_data(map, tenancy) do
    %{
      map
      | name: "#{tenancy.tenant.first_name} #{tenancy.tenant.last_name}",
        tenancy_id: tenancy.id
    }
  end

  defp icon_url(nil), do: nil

  defp icon_url(icon_url), do: icon_url.url
end
