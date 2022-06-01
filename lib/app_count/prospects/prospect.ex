defmodule AppCount.Prospects.Prospect do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prospects__prospects" do
    field :email, :string
    field :address, :map
    field :contact_date, :date
    field :contact_result, :string
    field :contact_type, :string
    field :move_in, :date
    field :name, :string
    field :phone, :string
    field :notes, :string
    field :referral, :string
    belongs_to :floor_plan, Module.concat(["AppCount.Properties.FloorPlan"])
    belongs_to :traffic_source, Module.concat(["AppCount.Prospects.TrafficSource"])
    belongs_to :admin, Module.concat(["AppCount.Admins.Admin"])
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])
    has_many :showings, Module.concat(["AppCount.Prospects.Showing"])

    timestamps()
  end

  @doc false

  def changeset(prospect, attrs) do
    prospect
    |> cast(
      attrs,
      [
        :name,
        :email,
        :contact_date,
        :traffic_source_id,
        :address,
        :move_in,
        :floor_plan_id,
        :phone,
        :contact_type,
        :contact_result,
        :notes,
        :admin_id,
        :property_id,
        :referral
      ]
    )
    |> validate_required([:name, :contact_date, :contact_type, :property_id])
  end
end
