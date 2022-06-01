defmodule AppCount.Public.PropertyRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Public.Property

  alias AppCount.Properties.Property, as: ClientProperty

  def client_property_from_code(code) do
    @schema
    |> Repo.get_by([code: code], prefix: "public")
    |> Repo.preload(:client)
    |> case do
      nil ->
        nil

      public_record ->
        Repo.get_by(ClientProperty, [code: code], prefix: public_record.client.client_schema)
    end
  end
end
