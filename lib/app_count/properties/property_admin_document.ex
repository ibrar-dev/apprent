defmodule AppCount.Properties.PropertyAdminDocument do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties__property_admin_documents" do
    belongs_to(:property, Module.concat(["AppCount.Properties.Property"]))
    belongs_to(:admin_document, Module.concat(["AppCount.Properties.AdminDocument"]))
    timestamps()
  end

  @doc false
  def changeset(property_admin_document, attrs) do
    property_admin_document
    |> cast(attrs, [:property_id, :admin_document_id])
    |> validate_required([:property_id, :admin_document_id])
  end
end
