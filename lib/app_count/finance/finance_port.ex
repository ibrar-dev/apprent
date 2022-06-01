defmodule AppCount.Core.Ports.FinancePort do
  @moduledoc """
  * gets the request attrs and token from the FinanceRecorder
  * choose the crrect adapter for this env
  * Create a request_spec
  * call the adapter with the request spec.
  """
  alias AppCount.Adapters.SoftLedgerAdapter
  use AppCount.Core.Ports.SoftLedgerBehaviour, :alias_requests_and_responses

  @softledger_adapter AppCount.adapters(:softledger, SoftLedgerAdapter)

  def fetch_token(adapter \\ @softledger_adapter) do
    adapter.fetch_token()
  end

  # ------------------------------------------------------   CASH RECEIPT
  def create_cash_receipt(
        %CreateCashReceiptRequest{} = create_cash_receipt_request,
        token,
        adapter \\ @softledger_adapter
      ) do
    request_spec =
      SoftLedgerAdapter.request_spec(request: create_cash_receipt_request, token: token)

    adapter.create_cash_receipt(request_spec)
  end

  # ------------------------------------------------------   INVOICE
  def create_invoice(
        %CreateInvoiceRequest{} = create_invoice_request,
        token,
        adapter \\ @softledger_adapter
      ) do
    request_spec = SoftLedgerAdapter.request_spec(request: create_invoice_request, token: token)

    adapter.create_invoice(request_spec)
  end

  def issue_invoice(
        %IssueInvoiceRequest{} = issue_invoice_request,
        token,
        adapter \\ @softledger_adapter
      ) do
    request_spec = SoftLedgerAdapter.request_spec(request: issue_invoice_request, token: token)

    adapter.issue_invoice(request_spec)
  end

  # ------------------------------------------------------   CUSTOMER
  def create_customer(
        %{name: _customer_name} = create_customer_request,
        token,
        adapter \\ @softledger_adapter
      ) do
    request_spec = SoftLedgerAdapter.request_spec(request: create_customer_request, token: token)
    adapter.create_customer(request_spec)
  end

  # ------------------------------------------------------   LOCATION
  def create_location(
        %{name: _property_name} = create_location_request,
        token,
        adapter \\ @softledger_adapter
      ) do
    request_spec = SoftLedgerAdapter.request_spec(request: create_location_request, token: token)
    adapter.create_location(request_spec)
  end

  # ------------------------------------------------------    ACCOUNT
  def create_account(
        create_account_request,
        token,
        adapter \\ @softledger_adapter
      ) do
    request_params = Map.from_struct(create_account_request)

    changeset =
      %CreateUpdateAccountRequest{}
      |> CreateUpdateAccountRequest.changeset(request_params)

    if changeset.valid? do
      request_spec = SoftLedgerAdapter.request_spec(request: create_account_request, token: token)
      adapter.create_account(request_spec)
    else
      {:error, errors_on(changeset)}
    end
  end

  def update_account(
        update_account_request,
        token,
        adapter \\ @softledger_adapter
      ) do
    request_spec = SoftLedgerAdapter.request_spec(request: update_account_request, token: token)
    adapter.update_account(request_spec)
  end

  def delete_account(
        delete_account_request,
        token,
        adapter \\ @softledger_adapter
      ) do
    request_spec = SoftLedgerAdapter.request_spec(request: delete_account_request, token: token)
    adapter.delete_account(request_spec)
  end

  # ------------------------------------------------------   PAYMENT
  def create_payment(
        %CreatePaymentRequest{} = create_payment_request,
        token,
        adapter \\ @softledger_adapter
      ) do
    request_spec = SoftLedgerAdapter.request_spec(request: create_payment_request, token: token)
    adapter.create_payment(request_spec)
  end

  # ---------------- Private -------------------

  defp errors_on(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map_join(", ", fn {key, val} -> ~s{#{key}: "#{val}"} end)
  end
end
