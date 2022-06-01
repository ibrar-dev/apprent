defmodule AppCount.Adapters.SoftLedgerAdapterTest do
  use AppCount.Case
  alias AppCount.Adapters.SoftLedgerAdapter
  alias AppCount.Core.Ports.RequestSpec
  use AppCount.Core.Ports.SoftLedgerBehaviour, :alias_requests_and_responses

  @parent_id AppCount.Adapters.SoftLedger.Config.load().parent_id

  # TODO move somewhere
  def set_expectation(bypass, response, status_code) do
    Bypass.expect(bypass, fn conn ->
      {:ok, body} = Poison.encode(response)
      Plug.Conn.resp(conn, status_code, body)
    end)
  end

  defp endpoint_url(port), do: "http://localhost:#{port}/"

  def setup_location do
    location_response_json = %{
      _id: 1110,
      id: "1110",
      name: "name",
      currency: "USD",
      description: "description",
      parent_id: 0,
      parent_path: [0],
      imageURL: "image/url/logo.jpg",
      entityname: "entityname",
      entityEmail: "entityEmail",
      entityPhone: "entityPhone",
      entityEIN: "entityEIN",
      paymentDetails: "paymentDetails",
      AddressId: 0,
      FXGLAccountId: 0,
      RAAccountId: 0
    }

    request_attrs = %{id: :set, parent_id: :set, name: :set}

    request = CreateLocationRequest.new(request_attrs)

    {request, location_response_json}
  end

  # ---------------------------------------------------   setup -----------------------------------
  setup do
    on_exit(fn -> ExternalService.reset_fuse(AppCount.Adapters.SoftLedgerAdapter.Service) end)
  end

  test "create_request" do
    request = %CreateLocationRequest{
      currency: "USD",
      id: :set,
      name: :set,
      parent_id: :set
    }

    # When
    result = SoftLedgerAdapter.encode_request(request)

    assert result == ~s[{"parent_id":"set","name":"set","id":"set","currency":"USD"}]
  end

  # --------------------------------------------------- Tests  -----------------------------------

  describe "journal " do
    test "get empty list", ~M[] do
      get_request = %GetJournalRequest{}

      unsafe_get_fn = fn request ->
        assert request.url == "https://sb-api.softledger.com/api/journals"
        %GetJournalResponse{}
      end

      request_spec = %RequestSpec{
        request: get_request,
        token: "A LONG TOKEN FROM SOFTLEDGER",
        verb: :get
      }

      # When
      {:ok, result} = SoftLedgerAdapter.get_journal(request_spec, unsafe_get_fn)

      # Then
      assert %GetJournalResponse{} = result
    end

    test "success for  " do
      request_attrs = %{id: :set, parent_id: :set, name: :set}
      request = CreateJournalRequest.new(request_attrs)
      response_json = %{}

      unsafe_call_fn = fn request ->
        assert request.url == "https://sb-api.softledger.com/api/journals"
        CreateJournalResponse.new(response_json)
      end

      request_spec = %RequestSpec{
        request: request,
        returning: CreateJournalResponse,
        verb: :post
      }

      # When
      {:ok, response} = SoftLedgerAdapter.create_journal(request_spec, unsafe_call_fn)

      # Then
      assert %CreateJournalResponse{} = response
    end

    test "delete journal", ~M[] do
      del_request = %DeleteJournalRequest{id: 5678}

      unsafe_delete_fn = fn request ->
        assert request.url == "https://sb-api.softledger.com/api/journals/5678"
        %{}
      end

      request_spec = %RequestSpec{
        request: del_request,
        token: "A LONG TOKEN FROM SOFTLEDGER",
        verb: :delete
      }

      # When
      {:ok, result} = SoftLedgerAdapter.delete_journal(request_spec, unsafe_delete_fn)

      # Then
      assert result == %{}
    end
  end

  describe "fetch_token" do
    setup do
      bypass = Bypass.open()
      ~M[ bypass]
    end

    test "success 201", ~M[ bypass ] do
      oauth_json = %{expires_in: 86400, access_token: "AccessTOKEN"}

      set_expectation(bypass, oauth_json, 200)

      request_spec = %RequestSpec{
        url: endpoint_url(bypass.port),
        verb: :oauth,
        returning: OAuthResponse
      }

      # When
      {:ok, response} = SoftLedgerAdapter.unsafe_call(request_spec)

      assert %OAuthResponse{} = response
      assert response.expires_in == 86400
      assert response.access_token == "AccessTOKEN"
    end
  end

  describe "create_location unsafe_post using real API" do
    setup do
      bypass = Bypass.open()

      ~M[ bypass]
    end

    test "success 201 create_location", ~M[ bypass] do
      {request, location_response_json} = setup_location()
      set_expectation(bypass, location_response_json, 201)

      request_spec = %RequestSpec{
        request: request,
        url: endpoint_url(bypass.port),
        verb: :post,
        token: "Some Token",
        returning: CreateLocationResponse
      }

      # When
      {:ok, response} = SoftLedgerAdapter.unsafe_call(request_spec)

      assert %CreateLocationResponse{} = response
    end
  end

  describe "create_cash_receipt" do
    test " CreateCashReceiptRequest.new()" do
      request_attrs = %{id: :set, parent_id: :set, name: :set}

      # When
      result = CreateCashReceiptRequest.new(request_attrs)

      # Then
      assert result == %CreateCashReceiptRequest{}
    end

    test "success for  " do
      request_attrs = %{id: :set, parent_id: :set, name: :set}
      request = CreateCashReceiptRequest.new(request_attrs)
      response_json = %{}

      unsafe_call_fn = fn request ->
        assert request.url == "https://sb-api.softledger.com/api/cashReceipts"
        CreateCashReceiptResponse.new(response_json)
      end

      request_spec = %RequestSpec{
        request: request,
        returning: CreateCashReceiptResponse,
        verb: :post
      }

      # When
      {:ok, response} = SoftLedgerAdapter.create_cash_receipt(request_spec, unsafe_call_fn)

      # Then
      assert %CreateCashReceiptResponse{} = response
    end

    # describe "delete_cash_receipt" do
    #   test "success for  ", ~M[] do
    #     del_request = %DeleteCashReceiptsRequest{id: 8989}

    #     unsafe_delete_fn = fn request ->
    #       assert request.url == "https://sb-api.softledger.com/api/cashReceipts/8989"
    #       %{}
    #     end

    #     request_spec = %RequestSpec{
    #       request: del_request,
    #       token: "A LONG TOKEN FROM SOFTLEDGER",
    #       verb: :delete
    #     }

    #     # When
    #     {:ok, result} = SoftLedgerAdapter.delete_cash_receipt(request_spec, unsafe_delete_fn)

    #     # Then
    #     assert result == %{}
    #   end
  end

  describe "create_location" do
    test " CreateLocationRequest.new()" do
      request_attrs = %{id: :set, parent_id: :set, name: :set}

      # When
      result = CreateLocationRequest.new(request_attrs)

      # Then
      assert result == %CreateLocationRequest{
               currency: "USD",
               id: :set,
               name: :set,
               parent_id: :set
             }
    end

    test "success for  " do
      {request, location_response_json} = setup_location()

      unsafe_call_fn = fn request ->
        assert request.url == "https://sb-api.softledger.com/api/locations"
        CreateLocationResponse.new(location_response_json)
      end

      request_spec = %RequestSpec{
        request: request,
        returning: CreateLocationResponse,
        verb: :post
      }

      # When
      {:ok, response} = SoftLedgerAdapter.create_location(request_spec, unsafe_call_fn)

      # Then
      assert %CreateLocationResponse{} = response
    end

    test "{:error, :fuse_blown" do
      {request, _location_response_json} = setup_location()

      expected_result = {:error, {:fuse_blown, Service}}

      unsafe_call_fn = fn _request -> expected_result end

      request_spec = %RequestSpec{
        request: request,
        verb: :post,
        returning: CreateLocationResponse
      }

      # When
      result = SoftLedgerAdapter.create_location(request_spec, unsafe_call_fn)

      # Then
      assert result == expected_result
    end
  end

  describe "delete_location" do
    test "success for  ", ~M[] do
      del_request = %DeleteLocationRequest{id: 8989}

      unsafe_delete_fn = fn request ->
        assert request.url == "https://sb-api.softledger.com/api/locations/8989"
        %{}
      end

      request_spec = %RequestSpec{
        request: del_request,
        token: "A LONG TOKEN FROM SOFTLEDGER",
        verb: :delete
      }

      # When
      {:ok, result} = SoftLedgerAdapter.delete_location(request_spec, unsafe_delete_fn)

      # Then
      assert result == %{}
    end
  end

  describe "create_account" do
    test " CreateUpdateAccountRequest.new()" do
      request_attrs = %{id: :set, parent_id: :set, name: :set}

      # When
      result = CreateUpdateAccountRequest.new(request_attrs)

      # Then
      assert result == %CreateUpdateAccountRequest{
               id: :set,
               LocationId: @parent_id,
               name: :set,
               naturalBalance: nil,
               number: nil,
               subtype: nil,
               type: nil
             }
    end

    test "success for  " do
      request = %CreateUpdateAccountRequest{}
      response_json = %{}

      unsafe_call_fn = fn request ->
        assert request.url == "https://sb-api.softledger.com/api/ledger_accounts"
        CreateUpdateAccountResponse.new(response_json)
      end

      request_spec = %RequestSpec{
        request: request,
        returning: CreateUpdateAccountResponse,
        verb: :post
      }

      # When
      {:ok, response} = SoftLedgerAdapter.create_account(request_spec, unsafe_call_fn)

      # Then
      assert %CreateUpdateAccountResponse{} = response
    end
  end

  describe "delete_account" do
    test "success for  " do
      unsafe_call_fn = fn request ->
        assert request.url == "https://sb-api.softledger.com/api/ledger_accounts/43232"
        %{}
      end

      request = %DeleteAccountRequest{id: 43232}

      request_spec = %RequestSpec{
        request: request,
        returning: Map,
        verb: :delete
      }

      # When
      {:ok, response} = SoftLedgerAdapter.delete_account(request_spec, unsafe_call_fn)

      # Then
      assert %{} = response
    end
  end

  describe "create_customer" do
    test " CreateCustomerRequest.new()" do
      request_attrs = %{name: "Ringo Starr"}

      # When
      result = CreateCustomerRequest.new(request_attrs)

      # Then
      assert result == %CreateCustomerRequest{name: "Ringo Starr"}
    end

    test "success for  " do
      request = CreateCustomerRequest.new(%{name: "Ringo Starr"})

      unsafe_call_fn = fn request ->
        assert request.url == "https://sb-api.softledger.com/api/customers"
        %CreateCustomerResponse{name: "Ringo Starr"}
      end

      request_spec = %RequestSpec{
        request: request,
        returning: CreateCustomerResponse,
        verb: :post
      }

      # When
      {:ok, response} = SoftLedgerAdapter.create_customer(request_spec, unsafe_call_fn)

      # Then
      assert %CreateCustomerResponse{} = response
    end
  end

  # -------------------------------------  INVOICE ---------------------

  describe "create_invoice" do
    setup do
      customer_id = 123
      create_invoice_request_params = %CreateInvoiceRequest{AgentId: customer_id}
      ~M[create_invoice_request_params]
    end

    test "success for  ", ~M[create_invoice_request_params] do
      unsafe_call_fn = fn request ->
        assert request.url == "https://sb-api.softledger.com/api/invoices"
        CreateInvoiceResponse.new(%{})
      end

      request_spec = %RequestSpec{
        request: create_invoice_request_params,
        returning: CreateInvoiceResponse,
        verb: :post
      }

      # When
      {:ok, response} = SoftLedgerAdapter.create_invoice(request_spec, unsafe_call_fn)

      # Then
      assert %CreateInvoiceResponse{} = response
    end
  end

  describe "issue_invoice" do
    test "successs" do
      issue_invoice_request_params = %IssueInvoiceRequest{id: 898_989}

      unsafe_call_fn = fn request ->
        assert request.url == "https://sb-api.softledger.com/api/invoices/898989/issue"
        StatusResponse.new(%{status: 200})
      end

      request_spec = %RequestSpec{
        request: issue_invoice_request_params,
        returning: :no_return_data,
        verb: :put
      }

      {:ok, response} = SoftLedgerAdapter.issue_invoice(request_spec, unsafe_call_fn)

      assert %StatusResponse{status: 200} = response
    end
  end

  # -------------------------------------  PAYMENT ---------------------

  describe "create_payment" do
    setup do
      today = AppCount.Core.Clock.today() |> to_string()

      create_payment_request_params = %CreatePaymentRequest{
        paymentDate: today,
        type: "cashreceipt",
        amount: 100.00,
        currency: "USD",
        LocationId: 123,
        InvoiceId: 456,
        CashReceiptId: 789
      }

      ~M[create_payment_request_params]
    end

    test "success for  ", ~M[create_payment_request_params] do
      unsafe_call_fn = fn request ->
        assert request.url == "https://sb-api.softledger.com/api/payments"
        CreateInvoiceResponse.new(%{})
      end

      request_spec = %RequestSpec{
        request: create_payment_request_params,
        returning: CreateInvoiceResponse,
        verb: :post
      }

      # When
      {:ok, response} = SoftLedgerAdapter.create_payment(request_spec, unsafe_call_fn)

      # Then
      assert %CreateInvoiceResponse{} = response
    end
  end
end
