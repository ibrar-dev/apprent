defmodule AppCount.Accounts.PaymentSource do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Accounts.PaymentSource

  @derive {Jason.Encoder,
           only: [
             :active,
             :id,
             :brand,
             :exp,
             :lock,
             :name,
             :num1,
             :type,
             :subtype,
             :last_4,
             :is_default
           ]}

  schema "accounts__payment_sources" do
    field :active, :boolean, default: true

    # For CC, this is card brand. For ACH, this is bank name
    field :brand, :string
    field :exp, :string
    field :lock, :naive_datetime
    field :name, :string
    field :num1, AppCount.Crypto.LocalCryptedData
    field :num2, AppCount.Crypto.LocalCryptedData

    # "cc" or "ba"
    field :type, :string

    # For ACH, this is "checking" or "savings" - for CC, this is blank, but in
    # the future could hold BIN look up info
    field :subtype, :string, default: ""
    field :last_4, :string

    # These fields are credit-card only, and serve to help interchange rates on
    # Authorize.net. We use them to indicate that we're using stored
    # credentials.
    field :original_network_transaction_id, :string
    # This will either be 0 or 1 - some card brands require a $0.01 initial
    # auth, but most require just a $0.00 auth.
    field :original_auth_amount_in_cents, :integer, default: 0
    field :is_tokenized, :boolean

    field :is_default, :boolean, default: false
    belongs_to :account, AppCount.Accounts.Account

    timestamps()
  end

  @doc false
  def changeset(payment_source, attrs) do
    payment_source
    |> cast(attrs, [
      :account_id,
      :active,
      :brand,
      :exp,
      :is_default,
      :is_tokenized,
      :last_4,
      :lock,
      :name,
      :num1,
      :num2,
      :original_auth_amount_in_cents,
      :original_network_transaction_id,
      :subtype,
      :type
    ])
    |> validate_required([:type, :name, :num1, :num2, :brand, :active, :account_id])
    |> validate_inclusion(:type, ["ba", "cc"], message: "must be ba or cc")
    |> validate_length(:name, at_least: 4)
    |> validate_subtype()
  end

  def changeset_for_update(%PaymentSource{} = payment_source, attrs \\ %{}) do
    payment_source
    |> cast(attrs, [:subtype, :active, :name, :is_default])
    |> validate_required([:active, :name])
    |> validate_length(:name, at_least: 4)
    |> validate_subtype()
  end

  @doc """
  We expect a bank account's subtype to be checking or savings

  We have no such expectations for credit cards

  Takes as changeset and returns a changeset
  """
  def validate_subtype(changeset) do
    type = Map.get(changeset.changes, :type)

    if type == "ba" do
      changeset
      |> validate_required(:subtype, message: "must be checking or savings")
      |> validate_inclusion(:subtype, ["checking", "savings"],
        message: "must be checking or savings"
      )
    else
      changeset
    end
  end
end
