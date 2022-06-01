defmodule AppCount.Core.RentSaga do
  @moduledoc """
  RentSaga tracks the process thru multiple steps while the tenant is making a payment
  ref: http://cqrs.nu/Faq
  From the FAQ

  ### What is a saga?
  An independent component that reacts to domain events in a cross-aggregate,
  eventually consistent manner. Time can also be a trigger.
  Sagas are sometimes purely reactive, and sometimes represent workflows.
  From an implementation perspective,
  a saga is a state machine that is driven forward by incoming events
  (which may come from many aggregates).
  Some states will have side effects,
  such as sending commands, talking to external web services, or sending emails.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @all_fields [
    :account_id,
    :amount_in_cents,
    :payment_confirmed_at,
    :payment_source_id,
    :failed_at,
    :processor_id,
    :credit_card_processor_id,
    :bank_account_processor_id,
    :started_at,
    :transaction_id,
    :property_id,
    :message,
    :ip_address,
    :surcharge_in_cents,
    :agreement_text,
    :total_amount_in_cents,
    :response_from_adapter,
    :accounting_notified_at,
    :yardi_notified_at,
    :originating_device,
    :payment_id,
    :zip_code_confirmed_at,
    :cvv_confirmed_at
  ]

  @required_for_update @all_fields --
                         [
                           :accounting_notified_at,
                           :agreement_text,
                           :bank_account_processor_id,
                           :credit_card_processor_id,
                           :failed_at,
                           :message,
                           :originating_device,
                           :payment_confirmed_at,
                           :payment_id,
                           :property_id,
                           :payment_source_id,
                           :processor_id,
                           :response_from_adapter,
                           :surcharge_in_cents,
                           :total_amount_in_cents,
                           :transaction_id,
                           :yardi_notified_at,
                           :zip_code_confirmed_at,
                           :cvv_confirmed_at
                         ]
  @required_for_insert @required_for_update --
                         [
                           :payment_source_id
                         ]
  @ui_fields @all_fields --
               [
                 :account_id,
                 :accounting_notified_at,
                 :agreement_text,
                 :bank_account_processor_id,
                 :credit_card_processor_id,
                 :ip_address,
                 :message,
                 :originating_device,
                 :payment_id,
                 :processor_id,
                 :response_from_adapter,
                 :started_at,
                 :total_amount_in_cents,
                 :transaction_id,
                 :yardi_notified_at
               ]

  @derive {Jason.Encoder, only: @ui_fields}

  schema "finance__rent_sagas" do
    field :amount_in_cents, :integer, default: 0
    field :surcharge_in_cents, :integer, default: 0
    field :message, :string, default: ""
    field :transaction_id, :string
    field(:property_id, :integer, default: nil)
    field :ip_address, :string
    field :started_at, :utc_datetime
    field :payment_confirmed_at, :utc_datetime
    field :failed_at, :utc_datetime
    field(:aggregate, :boolean, virtual: true, default: false)

    field(:agreement_text, :string)
    field(:total_amount_in_cents, :integer, default: 0)
    field(:response_from_adapter, :string)
    field(:accounting_notified_at, :utc_datetime)
    field(:yardi_notified_at, :utc_datetime)
    # "app" || "web" || "site"
    field(:originating_device, :string)

    # For CC transactions, we record these fields. Zip confirmed at is typically
    # the time of payment. CVV confirmed at is typically the time of tokenization,
    # saving for one-time payments. This is to help mitigate chargebacks.
    field(:zip_code_confirmed_at, :utc_datetime)
    field(:cvv_confirmed_at, :utc_datetime)

    belongs_to :account, AppCount.Accounts.Account
    belongs_to :processor, AppCount.Properties.Processor
    belongs_to :credit_card_processor, AppCount.Properties.Processor
    belongs_to :bank_account_processor, AppCount.Properties.Processor
    belongs_to :payment_source, AppCount.Accounts.PaymentSource
    belongs_to :payment, AppCount.Ledgers.Payment

    timestamps()
  end

  def changeset(session_payment, attrs) do
    session_payment
    |> cast(attrs, @all_fields)
    |> validate_required(@required_for_insert)
  end

  def update_changeset(session_payment, attrs) do
    session_payment
    |> cast(attrs, @all_fields)
    |> validate_required(@required_for_update)
  end
end
