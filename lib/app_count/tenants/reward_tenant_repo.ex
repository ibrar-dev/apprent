defmodule AppCount.Tenants.RewardTenantRepo do
  @moduledoc """
  RewardTenant loads all Reward and Accomplishment data for the give Tenant
  """
  use AppCount.Core.GenericRepo,
    schema: AppCount.Tenants.RewardTenant,
    preloads: [accomplishments: [:type], purchases: [:reward]]

  @message "Read Only.  To mutate use AppCount.Tenants.TenantRepo"

  @message "Read Only.  To mutate use AppCount.Tenants.TenantRepo"

  def insert(_attrs) do
    raise @message
  end

  def update(_schema, _attrs) do
    raise @message
  end
end
