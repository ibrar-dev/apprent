defmodule AppCount.Properties.Unit do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Core.Clock
  alias AppCount.Core.DateTimeRange

  schema "properties__units" do
    field(:address, :map)
    field(:area, :integer)
    field(:current_lease, :map, virtual: true)
    field(:external_id, :string)
    field(:number, :string)
    field(:status, :string)
    field(:uuid, Ecto.UUID)

    belongs_to :property, AppCount.Properties.Property
    belongs_to :floor_plan, AppCount.Properties.FloorPlan

    has_many :orders, AppCount.Maintenance.Order
    has_many :leases, AppCount.Leases.Lease
    has_many :showings, AppCount.Prospects.Showing
    has_many :packages, AppCount.Properties.Package
    has_many :cards, AppCount.Maintenance.Card

    many_to_many(:tenants, AppCount.Tenants.Tenant,
      join_through: Module.concat(["AppCount.Leases.Lease"])
    )

    has_many :tenancies, AppCount.Tenants.Tenancy

    many_to_many(:features, AppCount.Properties.Feature,
      join_through: Module.concat(["AppCount.Properties.UnitFeature"])
    )

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :address,
      :area,
      :external_id,
      :floor_plan_id,
      :number,
      :property_id,
      :status,
      :uuid
    ])
    |> validate_required([:number, :property_id])
    |> unique_constraint(
      :number,
      name: :properties__units_property_id_number_index,
      message: "number already exists for property"
    )
    |> unique_constraint(
      :external_id,
      name: :properties__units_external_id_index,
      message: "external_id already exists"
    )
  end

  def current_leases(%AppCount.Properties.Unit{} = unit, %DateTimeRange{} = datetime_range) do
    # All leases for the unit checking each date in date_range
    datetime_range
    |> DateTimeRange.date_range()
    |> Enum.reduce([], fn date, acc_leases ->
      lease_or_nil = current_lease(unit, date)
      [lease_or_nil | acc_leases]
    end)
    |> Enum.uniq()
    |> Enum.reject(fn lease -> is_nil(lease) end)
  end

  def current_lease(%AppCount.Properties.Unit{} = unit, %Date{} = date) do
    if unit.leases == [] do
      nil
    else
      lease = Enum.find(unit.leases, fn lease -> is_current_lease?(lease, date) end)

      if lease do
        lease
      else
        nil
      end
    end
  end

  # has been renewed
  defp is_current_lease?(%{renewal_id: renewal_id} = _lease, _date) when not is_nil(renewal_id) do
    false
  end

  # has not yet moved out
  defp is_current_lease?(%{actual_move_out: nil} = lease, date) do
    Clock.less_than_or_equal(lease.start_date, date)
  end

  # has moved out but after target date
  defp is_current_lease?(%{actual_move_out: move_out_date} = lease, date)
       when not is_nil(move_out_date) do
    Clock.less_than_or_equal(lease.start_date, date) &&
      Clock.less_than_or_equal(date, move_out_date)
  end
end
