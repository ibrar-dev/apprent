defmodule AppCount.RentApply.History do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.RentApply.AddressFormatter
  @behaviour AppCount.RentApply.ValidatableBehaviour
  @derive {Poison.Encoder,
           only: [
             :id,
             :address,
             :street,
             :unit,
             :city,
             :state,
             :zip,
             :landlord_name,
             :landlord_phone,
             :landlord_email,
             :rent,
             :rental_amount,
             :residency_length,
             :current
           ]}

  schema "rent_apply__histories" do
    field(:address, :string)
    field(:street, :string)
    field(:unit, :string)
    field(:city, :string)
    field(:state, :string)
    field(:zip, :string)
    field(:landlord_name, :string)
    field(:landlord_phone, :string)
    field(:landlord_email, :string)
    field(:rent, :boolean, default: false)
    field(:rental_amount, :decimal)
    field(:residency_length, :string)
    field(:current, :boolean)

    belongs_to(:application, Module.concat(["AppCount.RentApply.RentApplication"]),
      foreign_key: :application_id
    )

    timestamps()
  end

  @impl AppCount.RentApply.ValidatableBehaviour
  def validation_changeset(changeset, attrs) do
    changeset
    |> cast(
      attrs,
      [
        :address,
        :landlord_name,
        :landlord_phone,
        :landlord_email,
        :rent,
        :rental_amount,
        :residency_length,
        :current,
        :street,
        :unit,
        :zip,
        :state,
        :city
      ]
    )
    |> validate_required([:address, :rent])
  end

  @doc false
  def changeset(%AppCount.RentApply.History{} = history, %{"address" => %{} = addr} = attrs) do
    params =
      Map.merge(addr, %{"address" => AddressFormatter.format(addr), "street" => addr["address"]})

    changeset(history, Map.merge(attrs, params))
  end

  @doc false
  def changeset(%AppCount.RentApply.History{} = history, attrs) do
    history
    |> validation_changeset(attrs)
    |> cast(attrs, [:application_id])
    |> validate_required([:application_id])
  end
end
