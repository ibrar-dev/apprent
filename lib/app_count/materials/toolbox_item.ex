defmodule AppCount.Materials.ToolboxItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "materials__toolbox_items" do
    field :admin, :string
    field :status, :string, default: "pending"
    field :history, {:array, :map}, default: []
    field :return_stock, :integer
    belongs_to :stock, Module.concat(["AppCount.Materials.Stock"])
    belongs_to :material, Module.concat(["AppCount.Materials.Material"])
    belongs_to :tech, Module.concat(["AppCount.Maintenance.Tech"])
    belongs_to :assignment, Module.concat(["AppCount.Maintenance.Assignment"])

    timestamps()
  end

  @doc false
  def changeset(toolbox_item, attrs) do
    toolbox_item
    |> cast(attrs, [:admin, :status, :history, :stock_id, :material_id, :tech_id, :assignment_id])
    |> validate_required([:status, :stock_id, :material_id, :tech_id])
  end
end
