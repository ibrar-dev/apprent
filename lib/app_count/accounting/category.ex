defmodule AppCount.Accounting.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounting__categories" do
    field :name, :string
    field :num, :integer
    field :max, :integer
    field :is_balance, :boolean
    field :total_only, :boolean
    field :in_approvals, :boolean

    timestamps()
  end

  @doc false
  def changeset(account_category, attrs) do
    account_category
    |> cast(attrs, [:name, :num, :is_balance, :max, :total_only, :in_approvals])
    |> validate_required([:name, :num, :max])
    |> unique_constraint(:num)
    |> check_constraint(:num, name: :valid_number)
    |> check_constraint(:max, name: :valid_max_number)
  end
end
