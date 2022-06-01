defmodule AppCount.Maintenance.CardItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "maintenance__card_items" do
    field :completed, :date
    field :completed_by, :string
    field :confirmation, :map
    field :name, :string
    field :notes, :string
    field :scheduled, :date
    field :status, :string

    belongs_to :card, AppCount.Maintenance.Card
    belongs_to :tech, AppCount.Maintenance.Tech
    belongs_to :vendor, AppCount.Vendors.Vendor

    timestamps()
  end

  @doc false
  def changeset(card_item, attrs) do
    card_item
    |> cast(attrs, [
      :card_id,
      :completed,
      :completed_by,
      :confirmation,
      :name,
      :notes,
      :scheduled,
      :status,
      :tech_id,
      :vendor_id
    ])
    |> validate_required([:name, :card_id])
    |> unique_constraint(:duplicate, name: :maintenance__card_items_card_id_name_index)
  end
end
