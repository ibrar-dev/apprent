defmodule AppCount.Finance.Account do
  @moduledoc """
  Used for Finanacial Accounting
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Finance.Account

  @required_fields [:name, :number, :natural_balance, :type, :subtype]
  @optional_fields [:description]

  @derive {Jason.Encoder,
           only: [:name, :number, :natural_balance, :description, :type, :subtype, :id]}

  schema "finance__accounts" do
    field(:name, :string)
    field(:number, :string)
    field(:natural_balance, :string)
    field(:type, :string)
    field(:subtype, :string)
    field(:description, :string, default: "")

    timestamps()
  end

  def changeset(%Account{} = request, params \\ %{}) do
    request
    |> cast(
      params,
      @required_fields ++ @optional_fields
    )
    |> validate_required(@required_fields)
    |> validate_inclusion(:natural_balance, ["credit", "debit"],
      message: ~s[must be "credit" or "debit"]
    )
    |> validate_inclusion(:type, ["Asset", "Liability", "Equity", "Revenue", "Expense"],
      message: ~s[must be "Asset", "Liability", "Equity", "Revenue", or "Expense"]
    )
    |> validate_length(:description, max: 255)
    |> validate_length(:subtype, min: 2, max: 255)
    |> validate_length(:number, is: 8, message: "must be 8 digits")
    |> validate_format(:number, ~r(^\d{8}$), message: "must be 8 numeric digits")
    |> unique_constraint(:name)
    |> unique_constraint(:number)
  end
end
