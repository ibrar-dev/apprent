defmodule AppCount.RentApply.EmergencyContact do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.RentApply.AddressFormatter
  alias AppCount.RentApply.EmergencyContact
  alias AppCount.Core.SchemaHelper

  @behaviour AppCount.RentApply.ValidatableBehaviour
  @derive {Poison.Encoder,
           only: [
             :id,
             :name,
             :phone,
             :relation,
             :email
           ]}

  schema "rent_apply__emergency_contacts" do
    field(:address, :string)
    field(:name, :string)
    field(:phone, :string)
    field(:relationship, :string)
    field(:email, :string)

    belongs_to(:application, Module.concat(["AppCount.RentApply.RentApplication"]),
      foreign_key: :application_id
    )

    timestamps()
  end

  @impl AppCount.RentApply.ValidatableBehaviour
  def validation_changeset(changeset, params) do
    params = SchemaHelper.cleanup_email(params)

    changeset
    |> cast(params, [:name, :relationship, :phone, :email, :address])
    |> validate_required([:name, :relationship, :phone])
  end

  def changeset(%EmergencyContact{} = contact, %{"address" => %{}} = attrs) do
    address =
      attrs["address"]
      |> AddressFormatter.format()

    changeset(contact, Map.put(attrs, "address", address))
  end

  def changeset(%EmergencyContact{} = contact, params) do
    contact
    |> validation_changeset(params)
    |> cast(params, [:application_id])
    |> validate_required([:application_id])
  end
end
