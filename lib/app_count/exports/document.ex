defmodule AppCount.Exports.Document do
  use Ecto.Schema
  import Ecto.Changeset
  use AppCount.EctoTypes.Attachment

  schema "exports__documents" do
    field :name, :string
    field :notes, :string
    field :type, :string
    belongs_to :category, Module.concat(["AppCount.Exports.Category"])
    attachment(:document)

    timestamps()
  end

  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, [:name, :type, :notes, :category_id])
    |> cast_attachment(:document)
    |> validate_required([:name, :type, :category_id])
  end
end
