defmodule AppCount.Tenants.Tenant do
  alias AppCount.Tenants.Tenant
  alias AppCount.Core.SchemaHelper
  alias AppCount.Core.PhoneNumber
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :first_name,
             :last_name
           ]}

  # NOTE: residency_status as JS knows it
  #
  # if (moment(currentLease.start_date) > moment()) {
  #     return 'Future';
  #   } else if (currentLease.evicted && currentLease.actual_move_out) {
  #     return 'Evicted';
  #   } else if (currentLease.evicted) {
  #     return 'Under Eviction';
  #   } else if (currentLease.actual_move_out) {
  #     return 'Moved Out';
  #   } else if (currentLease.renewal) {
  #     return 'Renewal'
  #   } else if (isCurrent) {
  #     return 'Current Lease';
  #   } else {
  #     return 'Month to Month';
  #   }

  # All possible States and Transitions
  # ++Future => Current Lease -> ...
  #          => Current Lease -> Moved Out**
  #          => Current Lease -> Renewal**
  #          => Current Lease -> Under Eviction -> Evicted**
  #          => Current Lease -> Month to Month -> Under Eviction -> Evicted**
  #          => Current Lease -> Month to Month -> Moved Out**
  #                                             -> Current Lease => ...

  schema "tenants__tenants" do
    field(:email, :string)
    field(:external_id, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    # either "approved" or "cash" -- "cash" tenants cannot pay electronically
    field(:payment_status, :string)
    # residency_status is not a reliable field.  Never changed in code
    field(:residency_status, :string)
    field(:phone, :string)
    field(:invalid_phone, :string, default: "")
    field(:alarm_code, :string)
    field(:uuid, Ecto.UUID)
    field(:package_pin, :string)
    field(:aggregate, :boolean, virtual: true, default: false)

    many_to_many(
      :units,
      AppCount.Properties.Unit,
      join_through: AppCount.Leases.Lease
    )

    many_to_many(
      :leases,
      AppCount.Leases.Lease,
      join_through: AppCount.Properties.Occupancy
    )

    has_many(:accomplishments, AppCount.Rewards.Accomplishment)
    has_many(:packages, AppCount.Properties.Package)
    has_many(:payments, AppCount.Ledgers.Payment)
    has_many(:visits, AppCount.Properties.Visit)
    has_many(:documents, AppCount.Properties.Document)
    has_many(:emails, AppCount.Messaging.Email)
    has_many(:vehicles, AppCount.Tenants.Vehicle)
    has_many(:pets, AppCount.Tenants.Pet)
    has_many(:occupancies, AppCount.Properties.Occupancy)
    has_many(:tenancies, AppCount.Tenants.Tenancy)
    has_one(:insurance, AppCount.Properties.Insurance)
    has_one(:account, AppCount.Accounts.Account)
    has_one(:screening, AppCount.Leases.Screening)
    belongs_to(:application, AppCount.RentApply.RentApplication)

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = tenant, attrs) do
    attrs =
      attrs
      |> SchemaHelper.cleanup_email()
      |> canonical_invalid_phone()

    tenant
    |> cast(
      attrs,
      [
        :email,
        :first_name,
        :last_name,
        :payment_status,
        :residency_status,
        :uuid,
        :phone,
        :invalid_phone,
        :package_pin,
        :application_id,
        :alarm_code,
        :external_id
      ]
    )
    |> validate_required([:first_name, :last_name])
    |> unique_constraint(:uuid)
    |> unique_constraint(:external_id)
  end

  def to_map(%__MODULE__{} = struct) do
    struct
    |> Map.take([
      :email,
      :first_name,
      :last_name,
      :payment_status,
      :residency_status,
      :uuid,
      :phone,
      :package_pin,
      :application_id,
      :alarm_code,
      :external_id
    ])
  end

  def new(first_name, last_name) do
    uuid = Ecto.UUID.generate()
    %__MODULE__{first_name: first_name, last_name: last_name, uuid: uuid}
  end

  def full_name(%Tenant{first_name: first_name, last_name: last_name}) do
    "#{first_name} #{last_name}"
  end

  def autopay?(%Tenant{aggregate: true, account: %{autopay: %{active: true}}}) do
    true
  end

  def autopay?(%Tenant{aggregate: true} = _tenant) do
    false
  end

  defp canonical_invalid_phone(%{invalid_phone: ""} = params) do
    params
  end

  defp canonical_invalid_phone(%{invalid_phone: nil} = params) do
    %{params | invalid_phone: ""}
  end

  defp canonical_invalid_phone(%{invalid_phone: invalid_phone} = params) do
    invalid_phone =
      invalid_phone
      |> PhoneNumber.new()
      |> PhoneNumber.dial_string()

    %{params | invalid_phone: invalid_phone}
  end

  defp canonical_invalid_phone(params) do
    params
  end
end
