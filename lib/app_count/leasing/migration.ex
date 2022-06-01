# currently deprecated in favor of the AppCount.Yardi.Leasing modules, this most likely will not be needed
# not to be deleted yet until we can resolve permissions issues with Yardi

# defmodule AppCount.Leasing.Migration do
#  @moduledoc """
#    This is intended to be run one time only to migration our current tenants to our new
#    leasing/tenancy system. It will then be removed. NOT really production code.
#
#  """
#  alias AppCount.Repo
#  alias AppCount.Tenants.Tenant
#  alias AppCount.Tenants.TenantRepo
#  import Ecto.Query
#
#  def migrate_tenants() do
#    migrate_charge_codes()
#
#    select_unmigrated_tenants()
#    |> Enum.each(&migrate/1)
#  end
#
#  def migrate_charge_codes() do
#    # copy over the charge code table including ids
#    path = "/tmp/accounting__charge_codes"
#    File.mkdir_p(path)
#    full_path = "#{path}/codes.sql"
#
#    sql = """
#      COPY accounting__charge_codes TO '#{full_path}'
#    """
#
#    Ecto.Adapters.SQL.query(Repo, sql)
#
#    sql = """
#      COPY leasing__charge_codes(id, code, name, is_default, account_id, inserted_at, updated_at)
#      FROM '#{full_path}'
#    """
#
#    Ecto.Adapters.SQL.query(Repo, sql)
#  end
#
#  def select_unmigrated_tenants() do
#    from(
#      tenant in Tenant,
#      left_join: tenancy in assoc(tenant, :tenancies),
#      where: is_nil(tenancy.id),
#      select: tenant.id
#    )
#    |> Repo.all(prefix: client_schema)
#  end
#
#  def migrate(tenant_id) do
#    lease_params = TenantRepo.current_lease_for(tenant_id)
#
#    if lease_params do
#      case AppCount.Yardi.ImportLeaseCharges.import(tenant_id) do
#        {:ok, charge_params} ->
#          AppCount.Leasing.Utils.CreateNewTenancy.create_new_tenancy(%{
#            tenant_id: tenant_id,
#            unit_id: lease_params.unit_id,
#            charges: charge_params || [],
#            date: lease_params.start_date,
#            start_date: lease_params.start_date,
#            end_date: lease_params.end_date
#          })
#
#        _ ->
#          nil
#      end
#    end
#  end
# end
