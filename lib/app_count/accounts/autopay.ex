defmodule AppCount.Accounts.Autopay do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts__autopays" do
    belongs_to :account, AppCount.Accounts.Account
    belongs_to :payment_source, AppCount.Accounts.PaymentSource

    field :active, :boolean
    field :agreement_accepted_at, :utc_datetime
    field :agreement_text, :string, default: ""
    field :last_run, :date
    field :payer_ip_address, :string, default: ""

    timestamps()
  end

  @doc false
  def changeset(autopay, attrs) do
    autopay
    |> cast(
      attrs,
      [
        :active,
        :account_id,
        :payment_source_id,
        :last_run,
        :payer_ip_address,
        :agreement_text,
        :agreement_accepted_at
      ]
    )
    |> validate_required([:active, :account_id, :payment_source_id])
    |> unique_constraint(:unique,
      name: :accounts__autopays_account_id_index,
      message: "Only one autopay per account allowed"
    )
    |> unique_constraint(:unique,
      name: :accounts__autopays_payment_source_id_index,
      message: "Only one autopay per payment source"
    )
  end
end
