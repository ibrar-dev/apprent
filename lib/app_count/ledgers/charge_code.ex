defmodule AppCount.Ledgers.ChargeCode do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ledgers__charge_codes" do
    field :code, :string
    field :name, :string
    field :is_default, :boolean
    belongs_to :account, AppCount.Accounting.Account

    timestamps()
  end

  @doc false
  def changeset(charge_code, attrs) do
    charge_code
    |> cast(attrs, [:code, :name, :account_id, :is_default])
    |> validate_required([:code, :account_id])
    |> unique_constraint(:code, name: :accounting__charge_codes_code_index)
    |> unique_constraint(:default_code, name: :accounting__charge_account_id_default)
  end
end
