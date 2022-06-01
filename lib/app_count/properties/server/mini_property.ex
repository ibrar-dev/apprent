# ------------------------------------------------------------------
#      AppCount.Properties.Server.MiniProperty
# ------------------------------------------------------------------

defmodule AppCount.Properties.Server.MiniTenant do
  @moduledoc false
  use Ecto.Schema

  schema "tenants__tenants" do
  end
end

# ------------------------------------------------------------------
defmodule AppCount.Properties.Server.MiniOccupancy do
  @moduledoc false
  use Ecto.Schema

  schema "properties__occupancies" do
    belongs_to :tenant, AppCount.Properties.Server.MiniTenant, foreign_key: :tenant_id
    belongs_to :lease, AppCount.Properties.Server.MiniLease, foreign_key: :lease_id
  end
end

# ------------------------------------------------------------------
defmodule AppCount.Properties.Server.MiniLease do
  @moduledoc false
  use Ecto.Schema

  schema "leases__leases" do
    field :start_date, :date
    field :actual_move_out, :date
    field :end_date, :date
    belongs_to :unit, AppCount.Properties.Server.MiniUnit, foreign_key: :unit_id
    has_many :occupancies, AppCount.Properties.Server.MiniOccupancy, foreign_key: :lease_id

    timestamps()
  end
end

# ------------------------------------------------------------------
defmodule AppCount.Properties.Server.MiniUnit do
  @moduledoc false
  use Ecto.Schema

  schema "properties__units" do
    belongs_to :property, AppCount.Properties.Server.MiniProperty, foreign_key: :property_id
    has_many :leases, AppCount.Properties.Server.MiniLease, foreign_key: :unit_id
  end
end

# ------------------------------------------------------------------
defmodule AppCount.Properties.Server.MiniProperty do
  @moduledoc false
  use Ecto.Schema

  alias AppCount.Properties.Server.MiniProperty
  alias AppCount.Properties.Server.MiniUnit

  @repo AppCount.Properties.Server.MiniPropertyRepo

  schema "properties__properties" do
    has_one :setting, AppCount.Properties.Setting, foreign_key: :property_id
    has_many :units, AppCount.Properties.Server.MiniUnit, foreign_key: :property_id
  end

  def load_property(property_id, repo \\ @repo) do
    property = load_from_repo(property_id, repo)
    units = store_units(property.units)

    %MiniProperty{id: property.id, units: units, setting: property.setting}
  end

  def tenant(%MiniProperty{} = property, tenant_id) do
    case unit_lease_tenant(property, tenant_id) do
      :not_found ->
        :not_found

      {_unit, _lease, tenant} ->
        tenant
    end
  end

  # Query
  def unit_lease_tenant(%MiniProperty{} = property, tenant_id) do
    context = %{tenant_id: tenant_id, result: :not_found}

    context = tree_search(context, property, &unit_lease_tenant_rule/5)
    context.result
  end

  defp unit_lease_tenant_rule(context, unit, lease, _occupancy, tenant) do
    if tenant.id == context.tenant_id do
      %{context | result: {unit, lease, tenant}}
    else
      context
    end
  end

  # Query
  def current_tenant_ids(%MiniProperty{} = property) do
    context = %{today: AppCount.current_date(), result: []}
    context = tree_search(context, property, &current_tenant_ids_rule/5)
    context.result
  end

  defp current_tenant_ids_rule(%{result: tenant_ids} = context, _unit, lease, _occupancy, tenant) do
    if AppCount.Leases.Lease.current?(lease, context.today) do
      tenant_ids = [tenant.id | tenant_ids]
      %{context | result: tenant_ids}
    else
      context
    end
  end

  # Walks through the data tree: property -> units -> leases -> occupancy -> tenant,
  # and applies the node_eval_fn to each leaf-node,
  # accumulating answers in the context
  defp tree_search(context, %MiniProperty{units: units} = _property, node_eval_fn)
       when is_function(node_eval_fn) do
    Enum.reduce(units, context, fn %{leases: leases} = unit, context ->
      Enum.reduce(leases, context, fn %{occupancies: occupancies} = lease, context ->
        Enum.reduce(occupancies, context, fn %{tenant: tenant} = occupancy, context ->
          node_eval_fn.(context, unit, lease, occupancy, tenant)
        end)
      end)
    end)
  end

  # --------  Utility

  def store_units(units) do
    units
    |> Enum.map(fn unit ->
      leases =
        unit.leases
        |> sort_leases()

      %MiniUnit{id: unit.id, leases: leases}
    end)
  end

  def sort_leases(leases) do
    Enum.sort(leases, fn one, two ->
      Date.compare(one.start_date, two.start_date) == :lt
    end)
  end

  def load_from_repo(property_id, repo \\ @repo) when is_integer(property_id) do
    repo.get_aggregate(property_id)
  end

  def changeset(struct, _params \\ %{}) do
    # Do not use this struct to change data
    struct
  end
end
