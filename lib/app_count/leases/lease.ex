defmodule AppCount.Leases.Lease do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  import AppCount.EctoExtensions
  use AppCount.EctoTypes.Attachment
  alias AppCount.Core.Clock

  schema "leases__leases" do
    field :actual_move_in, :date
    field :actual_move_out, :date
    field :admin, :string
    field :bluemoon_lease_id, :string
    field :bluemoon_signature_id, :string
    field :closed, :boolean
    field :deposit_amount, :decimal
    field :end_date, :date
    field :expected_move_in, :date
    field :is_current, :boolean, virtual: true
    field :lease_date, :date
    field :move_out_date, :date
    field :no_renewal, :boolean
    field :notice_date, :date
    field :pending_bluemoon_lease_id, :string
    field :pending_bluemoon_signature_id, :string
    field :pending_default_lease_charges, {:array, :integer}
    # TODO 'property' is not tested. Where is this filled in?
    field :property, :string, virtual: true
    field :renewal_admin, :string
    field :dirty, :boolean
    field :start_date, :date
    attachment(:document)

    belongs_to :move_out_reason, AppCount.Settings.MoveOutReason
    belongs_to :renewal, AppCount.Leases.Lease
    belongs_to :renewal_package, AppCount.Leasing.RenewalPackage
    belongs_to :unit, AppCount.Properties.Unit

    has_many :bills, AppCount.Ledgers.Charge
    has_many :charges, AppCount.Properties.Charge
    has_many :custom_packages, AppCount.Leasing.CustomPackage
    has_many :occupancies, AppCount.Properties.Occupancy
    has_many :occupants, AppCount.Properties.Occupant
    has_many :payments, AppCount.Ledgers.Payment
    has_many :screenings, AppCount.Leases.Screening
    has_one :eviction, AppCount.Properties.Eviction
    has_one :form, AppCount.Leases.Form

    many_to_many :tenants, AppCount.Tenants.Tenant, join_through: AppCount.Properties.Occupancy

    timestamps()
  end

  @doc false
  def changeset(lease, attrs) do
    lease
    |> cast(
      attrs,
      [
        :lease_date,
        :start_date,
        :end_date,
        :renewal_id,
        :unit_id,
        :move_out_date,
        :actual_move_in,
        :actual_move_out,
        :expected_move_in,
        :notice_date,
        :deposit_amount,
        :bluemoon_lease_id,
        :pending_bluemoon_lease_id,
        :pending_default_lease_charges,
        :bluemoon_signature_id,
        :pending_bluemoon_signature_id,
        :move_out_reason_id,
        :renewal_package_id,
        :closed,
        :renewal_admin,
        :document_id,
        :admin,
        :no_renewal,
        :dirty
      ]
    )
    |> cast_attachment(:document)
    |> validate_required([:start_date, :end_date, :unit_id])
    |> check_constraint(:lease_duration, name: :valid_duration)
    |> validate_move_out()
    |> check_constraint(
      :actual_move_in,
      name: :non_future_move_in,
      message: "cannot be in the future"
    )
    |> check_constraint(
      :actual_move_out,
      name: :non_future_move_out,
      message: "cannot be in the future"
    )
    |> exclusion_constraint(
      :lease_term,
      name: :duration_overlap,
      message: "conflicts with another lease"
    )
  end

  def valid_dates?(params) do
    %{
      "start_date" => start_date,
      "end_date" => end_date,
      "unit_id" => unit_id
    } = params

    from(
      l in AppCount.Leases.Lease,
      where: l.unit_id == ^unit_id,
      where:
        between(
          ^convert_date(start_date),
          l.start_date,
          fragment(
            "CASE WHEN ? IS NULL THEN ? ELSE ? END",
            l.move_out_date,
            l.end_date,
            l.move_out_date
          )
        ) or
          between(
            ^convert_date(end_date),
            l.start_date,
            fragment(
              "CASE WHEN ? IS NULL THEN ? ELSE ? END",
              l.move_out_date,
              l.end_date,
              l.move_out_date
            )
          ),
      select: count(l.id)
    )
    |> AppCount.Repo.one()
    |> Kernel.==(0)
  end

  defp validate_move_out(changeset) do
    if get_change(changeset, :actual_move_out) != nil && get_field(changeset, :renewal_id) != nil do
      add_error(changeset, :actual_move_out, "Cannot edit move out since a renewal exists.")
    else
      changeset
    end
  end

  defp convert_date(date) when is_binary(date), do: AppCount.Core.Clock.date_from_iso8601!(date)

  defp convert_date(date), do: date

  def pending?(%{start_date: start_date}, %Date{} = on) do
    start_lease_in_future = Clock.less_than(on, start_date)
    start_lease_in_future
  end

  def current?(
        %{start_date: start_date, end_date: end_date, actual_move_out: actual_move_out},
        %Date{} = on
      ) do
    start_lease_in_past = Clock.less_than_or_equal(start_date, on)
    not_moved_out = !actual_move_out
    lease_not_expired = !(!!end_date && Clock.less_than_or_equal(end_date, on))

    start_lease_in_past && not_moved_out && lease_not_expired
  end
end
