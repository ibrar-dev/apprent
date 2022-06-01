defmodule AppCount.Settings.Damage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "settings__damages" do
    field :name, :string
    belongs_to :account, Module.concat(["AppCount.Accounting.Account"])
    timestamps()
  end

  @doc false
  def changeset(damages, attrs) do
    damages
    |> cast(attrs, [:name, :account_id])
    |> validate_required([:name, :account_id])
  end
end
