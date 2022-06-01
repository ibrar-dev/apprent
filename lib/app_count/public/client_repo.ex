defmodule AppCount.Public.ClientRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Public.Client

  def from_schema(schema) do
    Repo.get_by(@schema, client_schema: schema)
  end
end
