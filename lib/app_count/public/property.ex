defmodule AppCount.Public.Property do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "public"
  schema "properties" do
    field :code, :string
    field :schema_id, :integer
    belongs_to :client, AppCount.Public.Client

    timestamps()
  end

  @doc false
  def changeset(property, attrs) do
    property
    |> cast(attrs, [:code, :client_id, :schema_id])
    |> validate_required([:code, :client_id, :schema_id])
    |> unique_constraint(:code)
    |> unique_constraint([:client_id, :schema_id])
  end
end
