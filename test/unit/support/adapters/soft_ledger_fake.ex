defmodule AppCount.Support.Adapters.SoftLedgerFake do
  @moduledoc """
  Fake of the outside world using SoftLedger
  """
  use AppCount.Core.Ports.SoftLedgerBehaviour, :alias_requests_and_responses
  alias AppCount.Core.Ports.RequestSpec
  @behaviour SoftLedgerBehaviour

  @impl SoftLedgerBehaviour
  def request_spec(overrides) when is_list(overrides) do
    params =
      [
        url: :not_set,
        adapter: __MODULE__
      ]
      |> Keyword.merge(overrides)

    struct(AppCount.Core.Ports.RequestSpec, params)
  end

  @impl SoftLedgerBehaviour
  def fetch_token(_post_fn \\ &nop_call/0) do
    {:ok, %OAuthResponse{access_token: "A Token FROM AppCount.Support.Adapters.SoftLedgerFake"}}
  end

  @impl SoftLedgerBehaviour
  def create_cash_receipt(%RequestSpec{}, _post_fn \\ &nop_call/1) do
    %CreateCashReceiptResponse{description: "SoftLedger-From-SoftLedgerFake"}
  end

  @impl SoftLedgerBehaviour
  def create_invoice(%RequestSpec{}, _post_fn \\ &nop_call/1) do
    %CreateInvoiceResponse{externalId: "SoftLedger-From-SoftLedgerFake"}
  end

  @impl SoftLedgerBehaviour
  def issue_invoice(%RequestSpec{}, _post_fn \\ &nop_call/1) do
    %StatusResponse{status: 200}
  end

  @impl SoftLedgerBehaviour
  def create_customer(%RequestSpec{}, _post_fn \\ &nop_call/1) do
    %CreateCustomerResponse{id: "SoftLedger-From-SoftLedgerFake"}
  end

  @impl SoftLedgerBehaviour
  def delete_customer(%RequestSpec{}, _nop_call \\ &nop_call/1) do
    {:ok, "successfully deleted"}
  end

  @impl SoftLedgerBehaviour
  def create_location(%RequestSpec{}, _post_fn \\ &nop_call/1) do
    %CreateLocationResponse{id: "SoftLedger-location_id-From-SoftLedgerFake"}
  end

  @impl SoftLedgerBehaviour
  def delete_location(%RequestSpec{}, _nop_call \\ &nop_call/1) do
    {:ok, "successfully deleted"}
  end

  @impl SoftLedgerBehaviour
  def create_account(%RequestSpec{}, _post_fn \\ &nop_call/1) do
    %CreateUpdateAccountResponse{_id: "SoftLedger-account_id-From-SoftLedgerFake"}
  end

  @impl SoftLedgerBehaviour
  def update_account(%RequestSpec{}, _post_fn \\ &nop_call/1) do
    %CreateUpdateAccountResponse{_id: "SoftLedger-account_id-From-SoftLedgerFake"}
  end

  @impl SoftLedgerBehaviour
  def delete_account(%RequestSpec{}, _nop_call \\ &nop_call/1) do
    {:ok, "successfully deleted"}
  end

  @impl SoftLedgerBehaviour
  def create_payment(%RequestSpec{}, _post_fn \\ &nop_call/1) do
    %CreatePaymentResponse{_id: "SoftLedger-Payment-From-SoftLedgerFake"}
  end

  @impl SoftLedgerBehaviour
  def create_journal(%RequestSpec{}, _post_fn \\ &nop_call/1) do
    %CreateJournalResponse{_id: "SoftLedger-From-SoftLedgerFake"}
  end

  @impl SoftLedgerBehaviour
  def get_journal(%RequestSpec{}, _post_fn \\ &nop_call/1) do
    %GetJournalResponse{}
  end

  @impl SoftLedgerBehaviour
  def delete_journal(%RequestSpec{}, _nop_call \\ &nop_call/1) do
    {:ok, "successfully deleted"}
  end

  def nop_call(_arg) do
    # nop
  end

  def nop_call() do
    # nop
  end
end
