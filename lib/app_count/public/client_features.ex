defmodule AppCount.Public.ClientModule do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "public"
  schema "clients_modules" do
    field :enabled, :boolean
    belongs_to :client, AppCount.Public.Client
    belongs_to :module, AppCountAuth.Module
  end

  @doc false
  def changeset(client, attrs) do
    client
    |> cast(attrs, [:module_id, :enabled, :client_id])
    |> validate_required([:module_id, :client_id])
  end

  def assoc_changeset(client, attrs) do
    client
    |> cast(attrs, [:module_id, :enabled])
    |> validate_required([:module_id])
  end
end
