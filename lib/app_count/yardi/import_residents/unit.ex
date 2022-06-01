defmodule AppCount.Yardi.ImportResidents.Unit do
  alias AppCount.Repo
  alias AppCount.Properties
  alias AppCount.Core.ClientSchema

  def get_or_insert_unit(unit_number, property_id) do
    params = %{number: unit_number, property_id: property_id}
    Repo.get_by(Properties.Unit, Map.to_list(params)) || insert_unit(params)
  end

  defp insert_unit(params) do
    {:ok, unit} = Properties.create_unit(ClientSchema.new("dasmen", params))
    unit
  end
end
