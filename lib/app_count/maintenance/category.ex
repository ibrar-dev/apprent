defmodule AppCount.Maintenance.Category do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Maintenance.Category

  use EctoMaterializedPath

  schema "maintenance__categories" do
    field(:name, :string)
    field(:visible, :boolean, default: true)
    field(:third_party, :boolean, default: false)
    belongs_to(:parent, __MODULE__)
    has_many(:children, __MODULE__, foreign_key: :parent_id)
    has_many(:orders, Module.concat(["AppCount.Maintenance.Order"]), foreign_key: :category_id)
    field(:path, EctoMaterializedPath.Path, default: [])

    timestamps()
  end

  @doc false
  def changeset(%Category{} = category, %{"path" => path} = path_attrs) do
    attrs = Map.put(path_attrs, "parent_id", List.last(path))

    category
    |> cast(attrs, [:name, :path, :parent_id, :visible, :third_party])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :maintenance_categories_name_path_index)
  end

  def changeset(%Category{} = category, attrs) do
    category
    |> cast(attrs, [:name, :visible, :third_party])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :maintenance_categories_name_path_index)
  end
end
