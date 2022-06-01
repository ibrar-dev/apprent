defmodule AppCount.Core.Ports.FinancePortTest do
  use AppCount.Case
  alias AppCount.Core.Ports.FinancePort
  use AppCount.Core.Ports.SoftLedgerBehaviour, :alias_requests_and_responses

  @location_id "SoftLedger-location_id"

  defmodule SoftLedgerParrot do
    use TestParrot
    parrot(:accounting, :fetch_token, {:ok, %OAuthResponse{access_token: "A-TOKEN"}})
    parrot(:accounting, :create_location, {:ok, %{location_id: "SoftLedger-location_id"}})
    parrot(:accounting, :create_account, {:ok, %CreateUpdateAccountResponse{}})
    parrot(:accounting, :update_account, {:ok, %CreateUpdateAccountResponse{}})
    parrot(:accounting, :delete_account, {:ok, %{}})
    parrot(:accounting, :create_customer, {:ok, %{name: "Ringo Starr"}})
    parrot(:accounting, :create_invoice, {:ok, %{}})
    parrot(:accounting, :issue_invoice, {:ok, %{status: 200}})
    parrot(:accounting, :create_cash_receipt, {:ok, %{}})
    parrot(:accounting, :create_payment, {:ok, %{}})
  end

  alias AppCount.Core.Ports.FinancePortTest.SoftLedgerParrot

  test "fetch_token" do
    # When
    {:ok, o_auth_response} = FinancePort.fetch_token(SoftLedgerParrot)

    # Then
    assert o_auth_response.access_token == "A-TOKEN"
    assert_receive :fetch_token
  end

  test "create_payment/3" do
    request_attrs = %{}

    create_payment_request = CreatePaymentRequest.new(request_attrs)

    expected_request_spec =
      AppCount.Adapters.SoftLedgerAdapter.request_spec(
        request: create_payment_request,
        token: "Token-from-port"
      )

    # When
    result =
      FinancePort.create_payment(
        create_payment_request,
        "Token-from-port",
        SoftLedgerParrot
      )

    # Then
    assert result == {:ok, %{}}

    assert_receive {:create_payment, ^expected_request_spec}
  end

  test "create_cash_receipt/3" do
    request_attrs = %{}

    create_cash_receipt_request = CreateCashReceiptRequest.new(request_attrs)

    expected_request_spec =
      AppCount.Adapters.SoftLedgerAdapter.request_spec(
        request: create_cash_receipt_request,
        token: "Token-from-port"
      )

    # When
    result =
      FinancePort.create_cash_receipt(
        create_cash_receipt_request,
        "Token-from-port",
        SoftLedgerParrot
      )

    # Then
    assert result == {:ok, %{}}

    assert_receive {:create_cash_receipt, ^expected_request_spec}
  end

  test "create Invoice" do
    request_attrs = %{}

    create_invoice_request = CreateInvoiceRequest.new(request_attrs)

    expected_request_spec =
      AppCount.Adapters.SoftLedgerAdapter.request_spec(
        request: create_invoice_request,
        token: "Token-from-port"
      )

    # When
    result =
      FinancePort.create_invoice(create_invoice_request, "Token-from-port", SoftLedgerParrot)

    # Then
    assert result == {:ok, %{}}

    assert_receive {:create_invoice, ^expected_request_spec}
    # %AppCount.Core.Ports.RequestSpec{
    #   adapter: AppCount.Adapters.SoftLedgerAdapter,
    #   deps: %{},
    #   id: :not_set,
    #   request: %AppCount.Core.Ports.SoftLedgerBehaviour.CreateInvoiceRequest{
    #     AgentId: :not_set,
    #     InvoiceLineItems: [],
    #     LocationId: 876,
    #     currency: "USD"
    #   },
    #   returning: :not_set,
    #   token: "Token-from-port",
    #   url: :not_set,
    #   verb: :not_set
    # }}
  end

  test "issue Invoice" do
    request_attrs = %{id: 12345}

    issue_invoice_request = IssueInvoiceRequest.new(request_attrs)

    expected_request_spec =
      AppCount.Adapters.SoftLedgerAdapter.request_spec(
        request: issue_invoice_request,
        token: "Token-from-port"
      )

    # When
    result = FinancePort.issue_invoice(issue_invoice_request, "Token-from-port", SoftLedgerParrot)

    # Then
    assert result == {:ok, %{status: 200}}

    assert_receive {:issue_invoice, ^expected_request_spec}
  end

  test "create Customer" do
    request_attrs = %{name: "Ringo Starr"}

    create_customer_request = CreateCustomerRequest.new(request_attrs)

    expected_request_spec =
      AppCount.Adapters.SoftLedgerAdapter.request_spec(
        request: create_customer_request,
        token: "Token-from-port"
      )

    # When
    result =
      FinancePort.create_customer(create_customer_request, "Token-from-port", SoftLedgerParrot)

    # Then
    assert result == {:ok, %{name: "Ringo Starr"}}
    assert_receive {:create_customer, ^expected_request_spec}
  end

  test "create Location" do
    location_attrs = %{name: "Havana Falls"}

    expected_request_spec =
      AppCount.Adapters.SoftLedgerAdapter.request_spec(
        request: location_attrs,
        token: "Token-from-port"
      )

    # When
    result = FinancePort.create_location(location_attrs, "Token-from-port", SoftLedgerParrot)

    # Then
    assert result == {:ok, %{location_id: @location_id}}
    assert_receive {:create_location, ^expected_request_spec}
  end

  test "create account valid request" do
    random_num = Enum.random(10_000_000..99_999_999)

    request = %CreateUpdateAccountRequest{
      name: "account.name",
      naturalBalance: "credit",
      number: "#{random_num}",
      type: "Asset",
      subtype: "Asset"
    }

    expected_request_spec =
      AppCount.Adapters.SoftLedgerAdapter.request_spec(
        request: request,
        token: "Token-from-port"
      )

    # When
    {:ok, response} = FinancePort.create_account(request, "Token-from-port", SoftLedgerParrot)

    # Then
    assert %CreateUpdateAccountResponse{} = response
    assert_receive {:create_account, ^expected_request_spec}
  end

  test "create account invalid request" do
    request = %CreateUpdateAccountRequest{
      name: "account.name",
      naturalBalance: "credit",
      type: "Asset",
      subtype: "Asset"
    }

    expected_request_spec =
      AppCount.Adapters.SoftLedgerAdapter.request_spec(
        request: request,
        token: "Token-from-port"
      )

    # When
    {:error, message} = FinancePort.create_account(request, "Token-from-port", SoftLedgerParrot)

    # Then
    assert message == ~s[number: "can't be blank"]
    refute_receive {:create_account, ^expected_request_spec}
  end

  test "update account" do
    request = %{
      currency: "USD",
      id: :set,
      name: :set,
      parent_id: :set
    }

    expected_request_spec =
      AppCount.Adapters.SoftLedgerAdapter.request_spec(
        request: request,
        token: "Token-from-port"
      )

    # When
    {:ok, response} = FinancePort.update_account(request, "Token-from-port", SoftLedgerParrot)

    # Then
    assert %CreateUpdateAccountResponse{} = response
    assert_receive {:update_account, ^expected_request_spec}
  end

  test "delete account" do
    request = %{
      currency: "USD",
      id: :set,
      name: :set,
      parent_id: :set
    }

    expected_request_spec =
      AppCount.Adapters.SoftLedgerAdapter.request_spec(
        request: request,
        token: "Token-from-port"
      )

    # When
    {:ok, response} = FinancePort.delete_account(request, "Token-from-port", SoftLedgerParrot)

    # Then
    assert %{} = response
    assert_receive {:delete_account, ^expected_request_spec}
  end
end
