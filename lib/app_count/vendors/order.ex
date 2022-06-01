defmodule AppCount.Vendors.Order do
  use Ecto.Schema
  import Ecto.Changeset

  @required [:status, :vendor_id, :category_id, :uuid, :ticket, :priority]
  @fields @required ++
            [
              :card_item_id,
              :unit_id,
              :tenant_id,
              :creation_date,
              :scheduled,
              :has_pet,
              :entry_allowed,
              :created_by,
              :admin_id,
              :property_id
            ]

  @status_values ["Open", "Completed", "Canceled"]

  schema "vendors__orders" do
    # status can be: "Open" or ???
    field :status, :string, default: hd(@status_values)
    field :uuid, Ecto.UUID
    field :priority, :integer, default: 0
    field :ticket, :string, default: "UNKNOWN"
    field :creation_date, :date
    field :scheduled, :date
    field :has_pet, :boolean, default: false
    field :created_by, :string, default: nil
    field :entry_allowed, :boolean, default: false

    belongs_to :admin, AppCount.Admins.Admin
    belongs_to :card_item, AppCount.Maintenance.CardItem
    belongs_to :category, AppCount.Vendors.Category
    belongs_to :property, AppCount.Properties.Property
    belongs_to :tenant, AppCount.Tenants.Tenant
    belongs_to :unit, AppCount.Properties.Unit
    belongs_to :vendor, AppCount.Vendors.Vendor

    has_many :notes, AppCount.Vendors.Note

    timestamps()
  end

  def new(
        %{
          status: _status,
          vendor_id: _vendor_id,
          category_id: _category_id,
          uuid: _uuid,
          ticket: _ticket,
          priority: _priority
        } = attrs
      ) do
    struct(__MODULE__, attrs)
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, @fields)
    |> validate_required(@required)
  end
end
