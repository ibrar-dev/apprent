defmodule AppCount.Properties.Settings do
  @moduledoc """
  Convenience Methods for fetch settings
  """
  alias AppCount.Properties.Setting
  alias AppCount.Repo

  @doc """
  Fetch a Property Setting by property id (int)
  """
  def fetch_by_property_id(%AppCount.Core.ClientSchema{name: client_schema, attrs: id}) do
    Repo.get_by(Setting, [property_id: id], prefix: client_schema)
  end
end
