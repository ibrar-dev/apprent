defmodule AppCount.Accounting.InvoicePayment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounting__invoice_payments" do
    field :amount, :decimal
    field :post_month, :date
    belongs_to :reconciliation, Module.concat(["AppCount.Accounting.ReconciliationPosting"])
    belongs_to :invoicing, Module.concat(["AppCount.Accounting.Invoicing"])
    belongs_to :account, Module.concat(["AppCount.Accounting.Account"])
    belongs_to :check, Module.concat(["AppCount.Accounting.Check"])

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{post_month: pm} = payment, attrs) when not is_nil(pm),
    do: do_changeset(payment, attrs)

  def changeset(%__MODULE__{} = payment, %{"post_month" => p} = attrs) when not is_nil(p),
    do: do_changeset(payment, attrs)

  def changeset(%__MODULE__{} = payment, %{post_month: p} = attrs) when not is_nil(p),
    do: do_changeset(payment, attrs)

  def changeset(%__MODULE__{} = payment, %{"amount" => _} = attrs) do
    add_post_month(payment, attrs, "post_month")
  end

  def changeset(%__MODULE__{} = payment, %{amount: _} = attrs) do
    add_post_month(payment, attrs, :post_month)
  end

  defp add_post_month(payment, attrs, field) do
    post_month =
      AppCount.current_time()
      |> Timex.beginning_of_month()

    new_attrs = Map.put(attrs, field, post_month)
    changeset(payment, new_attrs)
  end

  defp do_changeset(invoice_payment, attrs) do
    invoice_payment
    |> cast(attrs, [
      :amount,
      :invoicing_id,
      :check_id,
      :post_month,
      :account_id,
      :reconciliation_id,
      :inserted_at
    ])
    |> validate_required([:amount, :post_month, :invoicing_id, :account_id])
    |> record_not_locked
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
