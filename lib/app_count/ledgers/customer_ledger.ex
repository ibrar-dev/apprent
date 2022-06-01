defmodule AppCount.Ledgers.CustomerLedger do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ledgers__customer_ledgers" do
    field :external_id, :string
    field :name, :string
    field :type, :string
    field :closed, :boolean
    belongs_to :property, AppCount.Properties.Property
    has_many :payments, AppCount.Ledgers.Payment
    has_many :charges, AppCount.Ledgers.Charge

    timestamps()
  end

  @doc false
  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:name, :type, :property_id, :external_id, :closed])
    |> validate_required([:name, :type, :property_id])
  end
end
