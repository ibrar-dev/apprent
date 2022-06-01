defmodule AppCount.Rewards.Type do
  use Ecto.Schema
  import Ecto.Changeset
  import AppCount.EctoTypes.Upload

  schema "rewards__types" do
    field :name, :string
    field :points, :integer
    field :active, :boolean
    field :monthly_max, :integer
    field :icon, upload_type("appcount-rewards:reward-icons", "reward-icon", public: true)

    timestamps()
  end

  @doc false
  def changeset(reward_type, attrs) do
    reward_type
    |> cast(attrs, [:name, :points, :active, :icon, :monthly_max])
    |> validate_required([:name])
  end

  def to_map(%__MODULE__{} = struct) do
    struct
    |> Map.take([:name, :points, :active, :icon, :monthly_max])
  end
end
