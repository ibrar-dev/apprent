defmodule AppCount.Accounting.Account do
  @moduledoc """
  AppCount.Accounting is Unused, deprecated.  instead use AppCount.Financial
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Accounting.Account

  schema "accounting__accounts" do
    field(:is_credit, :boolean)
    field(:is_balance, :boolean)
    field(:is_cash, :boolean)
    field(:is_payable, :boolean)
    field(:name, :string)
    field(:num, :integer)
    field(:description, :string)
    field(:external_id, :string)
    belongs_to :source, AppCount.Accounting.Category

    timestamps()
  end

  def credit_debit(%Account{is_credit: true}) do
    "credit"
  end

  def credit_debit(%Account{is_credit: false}) do
    "debit"
  end

  def changeset(account, attrs) do
    account
    |> cast(attrs, [
      :is_credit,
      :is_balance,
      :is_cash,
      :is_payable,
      :name,
      :num,
      :description,
      :source_id,
      :external_id
    ])
    |> validate_required([:name])
    |> unique_constraint(:name,
      name: :accounting__accounts_name_index,
      message: "Account already exists."
    )
    |> unique_constraint(:num,
      num: :accounting_accounts_num_index,
      mesage: "Account Number already taken"
    )
    |> check_constraint(:num, name: :valid_number, message: "Account number must be 8 digits")
  end
end
