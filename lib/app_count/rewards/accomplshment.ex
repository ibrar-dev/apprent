defmodule AppCount.Rewards.Accomplishment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rewards__accomplishments" do
    field :amount, :integer
    field :created_by, :string
    field :reason, :string
    field :reversal, :map
    belongs_to :tenant, AppCount.Tenants.Tenant
    belongs_to :type, AppCount.Rewards.Type

    timestamps()
  end

  @doc false
  def changeset(reward, attrs) do
    reward
    |> cast(attrs, [:amount, :reason, :created_by, :reversal, :tenant_id, :type_id])
    |> validate_required([:amount, :reason, :created_by, :tenant_id, :type_id])
  end
end
