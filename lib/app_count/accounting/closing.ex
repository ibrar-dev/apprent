defmodule AppCount.Accounting.Closing do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounting__closings" do
    field :closed_on, :date
    field :month, :date
    field :type, :string
    belongs_to :admin, Module.concat(["AppCount.Admins.Admin"])
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])

    timestamps()
  end

  @doc false
  def changeset(post_month, attrs) do
    post_month
    |> cast(attrs, [:month, :closed_on, :property_id, :admin_id, :type])
    |> validate_required([:month, :closed_on, :property_id, :admin_id, :type])
    |> unique_constraint(
      :month,
      name: :accounting__closings_month_property_id_type_index,
      message: "has already been closed"
    )
  end
end
