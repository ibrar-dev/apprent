defmodule AppCount.Maintenance.OpenHistory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "maintenance__open_history" do
    field(:open, :integer)
    belongs_to(:property, AppCount.Properties.Property)

    timestamps()
  end

  @doc false
  def changeset(open_history, attrs) do
    open_history
    |> cast(attrs, [:open, :property_id])
    |> validate_required([:open, :property_id])
  end
end
