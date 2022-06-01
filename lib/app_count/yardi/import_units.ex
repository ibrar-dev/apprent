defmodule AppCount.Yardi.ImportUnits do
  require Logger
  alias AppCount.Properties
  alias AppCount.Properties.Property
  alias AppCount.Properties.Processors
  alias AppCount.Repo
  alias AppCount.Properties.PropertyRepo
  alias AppCount.Core.ClientSchema
  # TEST TODO THIS ENTIRE FILE

  def perform(%Property{external_id: external_id, id: id} = property)
      when is_binary(external_id) do
    external_id
    |> Yardi.Gateway.get_unit_information(
      Processors.processor_credentials(ClientSchema.new("dasmen", id), "management")
    )
    |> perform_import(property)
  end

  def perform(%Property{} = p), do: raise("No external ID found for property #{p.name}")

  def perform(property_id), do: perform(Repo.get(Property, property_id))

  def perform_import(units, property) do
    units
    |> Enum.map(&import_unit(&1, property))
  end

  def import_unit(
        %Yardi.Response.GetUnitInformation.Unit{} = unit,
        %{id: property_id} = _property
      ) do
    params =
      unit
      |> Map.from_struct()
      |> Map.put(:property_id, property_id)

    ClientSchema.new("dasmen", params)
    |> Properties.create_unit()
    |> case do
      {:ok, u} -> {:success, u.number}
      _ -> {:error, unit.number}
    end
  end

  def remove_units_not_in_request(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: %Property{external_id: external_id, id: id} = property
      })
      when is_binary(external_id) do
    external_id
    |> Yardi.Gateway.get_unit_information(
      Processors.processor_credentials(ClientSchema.new("dasmen", id), "management")
    )
    |> perform_surgery(ClientSchema.new(client_schema, property))
  end

  def remove_units_not_in_request(%Property{} = p),
    do: raise("No external ID found for property #{p.name}")

  def remove_units_not_in_request(property_id),
    do: remove_units_not_in_request(Repo.get(Property, property_id))

  def perform_surgery(units, %AppCount.Core.ClientSchema{name: client_schema, attrs: property}) do
    in_request =
      units
      |> Enum.map(& &1.number)
      |> Enum.uniq()

    in_apprent =
      PropertyRepo.units(ClientSchema.new(client_schema, property.id))
      |> Enum.map(& &1.number)
      |> Enum.uniq()

    in_apprent
    |> Enum.filter(fn a ->
      if Enum.member?(in_request, a) do
        false
      else
        true
      end
    end)
  end
end
