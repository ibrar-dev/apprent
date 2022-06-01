defmodule AppCount.Rewards.Purchase do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rewards__purchases" do
    field :points, :integer
    field :status, :string
    belongs_to :reward, AppCount.Rewards.Reward, foreign_key: :reward_id
    belongs_to :tenant, AppCount.Tenants.Tenant
    belongs_to :property, AppCount.Properties.Property

    timestamps()
  end

  @doc false
  def changeset(purchase, attrs) do
    purchase
    |> cast(attrs, [:status, :points, :tenant_id, :reward_id, :property_id])
    |> validate_required([:status, :points, :tenant_id, :reward_id, :property_id])
  end

  def to_map(%__MODULE__{} = struct) do
    struct
    |> Map.take([:status, :points, :tenant_id, :reward_id, :property_id])
  end
end
