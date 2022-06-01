defmodule AppCount.Properties.AdminDocument do
  use Ecto.Schema
  import Ecto.Changeset
  import AppCount.EctoTypes.Attachment

  schema "properties__admin_documents" do
    field :name, :string
    field :type, :string
    field :creator, :string
    attachment(:document)

    timestamps()
  end

  @doc false
  def changeset(admin_document, attrs) do
    admin_document
    |> cast(attrs, [:name, :type, :creator])
    |> cast_attachment(:document)
    |> validate_required([:name, :type, :creator])
  end
end
