defmodule AppCount.Ledgers.Payment do
  use Ecto.Schema
  import Ecto.Changeset
  use AppCount.EctoTypes.Attachment

  schema "ledgers__payments" do
    field(:admin, :string)
    field(:agreement_accepted_at, :utc_datetime)
    field(:agreement_text, :string, default: "")
    field(:amount, :decimal)
    field(:description, :string)
    field(:edits, {:array, :map})
    field(:external_id, :string)
    field(:last_4, :string, default: "")
    field(:memo, :string)
    field(:payer, :string)
    field(:payer_ip_address, :string, default: "")
    field(:payer_name, :string, default: "")
    field(:payment_type, :string, default: "")
    field(:post_error, :string)
    field(:post_month, :date)
    field(:refund_date, :date)
    field(:response, :map, default: %{})
    field(:source, :string)
    field(:status, :string, default: "cleared")
    field(:surcharge, :decimal, default: 0)
    field(:transaction_id, :string)
    field(:zip_code_confirmed_at, :utc_datetime)
    field(:cvv_confirmed_at, :utc_datetime)
    field(:rent_application_terms_and_conditions, :string, default: "")

    attachment(:image)

    belongs_to :reconciliation, AppCount.Accounting.ReconciliationPosting
    belongs_to(:application, AppCount.RentApply.RentApplication)
    belongs_to(:batch, AppCount.Ledgers.Batch)
    belongs_to(:lease, AppCount.Leases.Lease)
    belongs_to(:payment_source, AppCount.Accounts.PaymentSource)
    belongs_to(:property, AppCount.Properties.Property)
    belongs_to(:tenant, AppCount.Tenants.Tenant)
    belongs_to(:customer_ledger, AppCount.Ledgers.CustomerLedger)
    has_many(:receipts, AppCount.Accounting.Receipt)
    has_one(:nsf, AppCount.Ledgers.Charge, foreign_key: :nsf_id)

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{post_month: pm} = payment, attrs) when not is_nil(pm),
    do: do_changeset(payment, attrs)

  def changeset(%__MODULE__{} = payment, %{"post_month" => p} = attrs) when not is_nil(p),
    do: do_changeset(payment, attrs)

  def changeset(%__MODULE__{} = payment, %{post_month: p} = attrs) when not is_nil(p),
    do: do_changeset(payment, attrs)

  def changeset(%__MODULE__{} = payment, %{"property_id" => _} = attrs) do
    add_post_month(payment, attrs, "post_month")
  end

  def changeset(%__MODULE__{} = payment, %{property_id: _} = attrs) do
    add_post_month(payment, attrs, :post_month)
  end

  defp add_post_month(payment, attrs, field) do
    post_month =
      AppCount.current_time()
      |> Timex.beginning_of_month()

    new_attrs = Map.put(attrs, field, post_month)
    changeset(payment, new_attrs)
  end

  defp do_changeset(payment, attrs) do
    payment
    |> cast(
      attrs,
      [
        :admin,
        :agreement_accepted_at,
        :agreement_text,
        :amount,
        :application_id,
        :batch_id,
        :description,
        :edits,
        :external_id,
        :image_id,
        :inserted_at,
        :last_4,
        :lease_id,
        :memo,
        :payer,
        :payer_ip_address,
        :payer_name,
        :payment_source_id,
        :payment_type,
        :post_error,
        :post_month,
        :property_id,
        :reconciliation_id,
        :refund_date,
        :response,
        :source,
        :status,
        :surcharge,
        :tenant_id,
        :transaction_id,
        :zip_code_confirmed_at,
        :cvv_confirmed_at,
        :customer_ledger_id,
        :rent_application_terms_and_conditions
      ]
    )
    |> cast_attachment(:image)
    |> record_not_locked
    |> validate_required([
      :amount,
      :post_month,
      :property_id,
      :response,
      :source,
      :status,
      :surcharge,
      :transaction_id
    ])
    |> unique_constraint(:transaction_id)
    |> check_constraint(:post_month, name: :valid_post_month)
  end

  def record_not_locked(changeset) do
    is_locked(changeset, fetch_field(changeset, :reconciliation_id))
  end

  defp is_locked(changeset, {:data, value}) when value != nil do
    add_error(
      changeset,
      :reconciliation,
      "This payment was already reconciled and cannot be changed."
    )
  end

  defp is_locked(changeset, _) do
    changeset
  end
end
