defmodule AppCount.Public.Utils.Properties do
  alias AppCount.Properties.Property, as: ClientProperty
  alias AppCount.Public.PropertyRepo

  def sync_public(%ClientProperty{__meta__: meta, code: code, id: schema_id} = client_property) do
    client = AppCount.Public.ClientRepo.from_schema(meta.prefix)

    case PropertyRepo.get_by([schema_id: schema_id, client_id: client.id], prefix: "public") do
      nil ->
        %{code: code, client_id: client.id, schema_id: schema_id}
        |> PropertyRepo.insert(prefix: "public")
        |> add_ref(client_property)

      public_record ->
        PropertyRepo.update(public_record, %{code: code}, prefix: "public")
        |> add_ref(client_property)
    end
  end

  defp add_ref({:ok, public_property}, client_property) do
    {:ok, client_property} =
      AppCount.Properties.PropertyRepo.update(client_property, %{
        public_property_id: public_property.id
      })

    {:ok, public_property, client_property}
  end

  defp add_ref(e, _), do: e
end
