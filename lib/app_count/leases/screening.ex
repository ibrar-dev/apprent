defmodule AppCount.Leases.Screening do
  use Ecto.Schema
  import Ecto.Changeset

  schema "leases__screenings" do
    field :first_name, :string
    field :last_name, :string
    field :phone, :string
    field :email, :string
    field :city, :string
    field :dob, :date
    field :income, :decimal
    field :ssn, AppCount.Crypto.LocalCryptedData
    field :gateway_xml, :string
    field :xml_data, {:array, :string}
    field :state, :string
    field :street, :string
    field :zip, :string
    field :rent, :decimal
    field :linked_orders, {:array, :string}
    field :url, :string
    field :order_id, :string
    field :status, :string
    field :decision, :string
    belongs_to :tenant, AppCount.Tenants.Tenant
    belongs_to :lease, AppCount.Leases.Lease
    belongs_to :person, AppCount.RentApply.Person
    belongs_to :property, AppCount.Properties.Property

    timestamps()
  end

  @doc false
  def changeset(persons, attrs) do
    persons
    |> cast(
      attrs,
      [
        :first_name,
        :last_name,
        :phone,
        :email,
        :tenant_id,
        :lease_id,
        :person_id,
        :property_id,
        :street,
        :city,
        :state,
        :zip,
        :dob,
        :ssn,
        :income,
        :rent,
        :linked_orders,
        :url,
        :order_id,
        :status,
        :decision,
        :xml_data
      ]
    )
    |> validate_required([
      :property_id,
      :first_name,
      :last_name,
      :phone,
      :email,
      :city,
      :street,
      :state,
      :zip,
      :dob,
      :ssn,
      :income,
      :rent
    ])
    |> unique_constraint(:person_id)
    |> unique_constraint(:tenant_id)
    |> check_constraint(:assoc, name: :must_have_assoc)
  end
end
