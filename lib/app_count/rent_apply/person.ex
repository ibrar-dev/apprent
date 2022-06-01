defmodule AppCount.RentApply.Person do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Core.SchemaHelper

  @behaviour AppCount.RentApply.ValidatableBehaviour

  # @phone ~r/^\d{3}[\s-.]?\d{3}[\s-.]?\d{4}$/

  @status_types ["Lease Holder", "Occupant", "Guarantor"]

  @derive {Poison.Encoder,
           only: [
             :full_name,
             :ssn,
             :email,
             :home_phone,
             :work_phone,
             :cell_phone,
             :dob,
             :dl_number,
             :dl_state,
             :status,
             :id
           ]}

  schema "rent_apply__persons" do
    field(:full_name, :string)
    field(:virtual_ssn, :string, virtual: true)
    field(:ssn, AppCount.Crypto.LocalCryptedData)
    field(:email, :string)
    field(:home_phone, :string)
    field(:work_phone, :string)
    field(:cell_phone, :string)
    field(:dob, :date)
    field(:dl_number, :string)
    field(:dl_state, :string)
    field(:status, :string)
    field(:order_id, :string)

    belongs_to(:application, AppCount.RentApply.RentApplication, foreign_key: :application_id)

    has_many(:employments, AppCount.RentApply.Employment)
    has_one(:screening, AppCount.Leases.Screening)

    timestamps()
  end

  @doc false
  def changeset(%AppCount.RentApply.Person{} = applicant, attrs) do
    attrs = SchemaHelper.cleanup_email(attrs)

    applicant
    |> validation_changeset(attrs)
    |> cast(attrs, [
      :application_id,
      :order_id
    ])
    |> validate_required([
      :application_id
    ])
  end

  def copy_ssn(%{"virtual_ssn" => ""} = attrs) do
    attrs
  end

  def copy_ssn(%{"virtual_ssn" => virtual_ssn} = attrs) do
    attrs
    |> Map.put("ssn", virtual_ssn)
  end

  def copy_ssn(%{} = attrs) do
    attrs
  end

  @impl AppCount.RentApply.ValidatableBehaviour
  def validation_changeset(changeset, attrs) do
    attrs = copy_ssn(attrs)

    changeset
    |> cast(attrs, [
      :full_name,
      :ssn,
      :email,
      :home_phone,
      :work_phone,
      :status,
      :cell_phone,
      :dob,
      :dl_number,
      :dl_state
    ])
    |> validate_required([
      :full_name,
      :ssn,
      :email,
      :status,
      :dob,
      :dl_number,
      :dl_state
    ])
    |> validate_inclusion(:status, @status_types)
    |> check_constraint(
      :home_phone,
      name: :must_have_a_phone,
      message: "Must have at least 1 phone number"
    )
  end
end
