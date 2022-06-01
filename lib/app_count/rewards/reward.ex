defmodule AppCount.Rewards.Reward do
  use Ecto.Schema
  import Ecto.Changeset
  import AppCount.EctoTypes.Upload

  schema "rewards__rewards" do
    field :icon, upload_type("appcount-rewards:prize-icons", "prize-icon", public: true)
    field :name, :string
    field :points, :integer
    field :price, :decimal
    field :promote, :boolean
    field :url, :string
    has_many :purchases, AppCount.Rewards.Purchase

    timestamps()
  end

  @doc false
  def changeset(reward, attrs) do
    reward
    |> cast(attrs, [:name, :icon, :points, :price, :url, :promote])
    |> validate_required([:name, :points])
  end
end
