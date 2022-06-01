defmodule AppCount.Tenants.RewardTenant do
  @moduledoc """
  RewardTenant is a special more limited form of AppCount.Tenants.Tenant
  it is readonly
  So in a way, we can think of it as a DB view
  """
  use Ecto.Schema
  alias AppCount.Tenants.RewardTenant

  schema "tenants__tenants" do
    field(:first_name, :string)
    field(:last_name, :string)

    field(:uuid, Ecto.UUID)

    has_many(:accomplishments, AppCount.Rewards.Accomplishment,
      foreign_key: :tenant_id,
      where: [reversal: nil]
    )

    has_many(:purchases, AppCount.Rewards.Purchase, foreign_key: :tenant_id)

    timestamps()
  end

  def changeset(_tenant, _attrs) do
    raise "Read Only.  Use AppCount.Tenants.Tenant to update this table"
  end

  def name(%RewardTenant{first_name: first_name, last_name: last_name}) do
    "#{first_name} #{last_name}"
  end
end
