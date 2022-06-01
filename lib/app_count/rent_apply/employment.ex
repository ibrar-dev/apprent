defmodule AppCount.RentApply.Employment do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.RentApply.AddressFormatter
  alias AppCount.Core.SchemaHelper

  @behaviour AppCount.RentApply.ValidatableBehaviour

  @derive {Poison.Encoder,
           only: [:address, :duration, :employer, :phone, :email, :salary, :supervisor, :current]}

  schema "rent_apply__employments" do
    field(:address, :string)
    field(:duration, :string)
    field(:employer, :string)
    field(:phone, :string)
    field(:email, :string)
    field(:salary, :decimal)
    field(:supervisor, :string)
    field(:current, :boolean)

    belongs_to(:application, Module.concat(["AppCount.RentApply.RentApplication"]),
      foreign_key: :application_id
    )

    belongs_to(:person, Module.concat(["AppCount.RentApply.Person"]))

    timestamps()
  end

  @impl AppCount.RentApply.ValidatableBehaviour
  def validation_changeset(changeset, %{"address" => %{}} = attrs) do
    address =
      attrs["address"]
      |> AddressFormatter.format()

    validation_changeset(changeset, Map.put(attrs, "address", address))
  end

  @impl AppCount.RentApply.ValidatableBehaviour
  def validation_changeset(changeset, params) do
    params = SchemaHelper.cleanup_email(params)

    changeset
    |> cast(
      params,
      [
        :employer,
        :address,
        :duration,
        :supervisor,
        :salary,
        :phone,
        :email,
        :current
      ]
    )
    |> validate_required([
      :employer,
      :address,
      :duration,
      :supervisor,
      :salary,
      :phone
    ])
  end

  @doc false
  def changeset(employment, %{"address" => %{}} = params) do
    address =
      params["address"]
      |> AddressFormatter.format()

    changeset(employment, Map.put(params, "address", address))
  end

  def changeset(employment, params) do
    employment
    |> validation_changeset(params)
    |> cast(
      params,
      [
        :application_id,
        :person_id
      ]
    )
    |> validate_required([
      :application_id,
      :person_id
    ])
  end
end
