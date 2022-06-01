defmodule AppCount.Exports.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "exports__categories" do
    field :name, :string
    belongs_to :admin, Module.concat(["AppCount.Admins.Admin"])
    has_many :documents, Module.concat(["AppCount.Exports.Document"])

    timestamps()
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :admin_id])
    |> validate_required([:name, :admin_id])
  end
end
