defmodule AppCount.Finance.InvoiceSagaTest do
  use AppCount.DataCase, async: true
  use AppCount.Core.Ports.SoftLedgerBehaviour, :alias_requests_and_responses

  alias AppCount.Finance.InvoiceSaga
  alias AppCount.Finance.SoftLedgerTranslation
  alias AppCount.Core.InvoiceSagaTopic
  @parent_id AppCount.Adapters.SoftLedger.Config.load().parent_id

  defmodule InvoiceSagaParrot do
    use TestParrot
    parrot(:invoice_saga, :rent_application, %InvoiceSaga{})
    parrot(:invoice_saga, :rent_payment, %InvoiceSaga{})
    parrot(:invoice_saga, :validate_after_load, %InvoiceSaga{})
    parrot(:invoice_saga, :create_customer_for_application, %InvoiceSaga{})
    parrot(:invoice_saga, :add_items, %InvoiceSaga{})
    parrot(:invoice_saga, :create_invoice, %InvoiceSaga{})
    parrot(:invoice_saga, :issue_invoice, %InvoiceSaga{})
    parrot(:invoice_saga, :create_cash_receipt, %InvoiceSaga{})
    parrot(:invoice_saga, :create_payment, %InvoiceSaga{})
    parrot(:invoice_saga, :log_errors, %InvoiceSaga{})
    parrot(:invoice_saga, :publish_result, %InvoiceSaga{})
  end

  defmodule FinancePortParrot do
    use TestParrot

    @create_location_reply {:ok,
                            %CreateLocationResponse{
                              id: "Location From FinancePortParrot"
                            }}
    @create_account_reply {:ok,
                           %CreateUpdateAccountResponse{
                             _id: "Ledger From FinancePortParrot"
                           }}

    @create_customer_reply {:ok,
                            %CreateCustomerResponse{
                              _id: "Ledger From FinancePortParrot"
                            }}

    @create_invoice_reply {:ok,
                           %CreateInvoiceResponse{
                             _id: "Invoice From FinancePortParrot"
                           }}
    @issue_invoice_reply {:ok,
                          %StatusResponse{
                            status: 200
                          }}

    @create_cash_receipt_reply {:ok,
                                %CreateCashReceiptResponse{
                                  _id: "Invoice From FinancePortParrot"
                                }}
    @create_payment_reply {:ok,
                           %CreatePaymentResponse{
                             _id: "Payment From FinancePortParrot"
                           }}

    parrot(:finance_port, :fetch_token, {:ok, %OAuthResponse{access_token: "A-TOKEN"}})
    parrot(:finance_port, :create_location, @create_location_reply)
    parrot(:finance_port, :create_account, @create_account_reply)
    parrot(:finance_port, :update_account, @create_account_reply)
    parrot(:finance_port, :delete_account, {:ok, %{}})
    parrot(:finance_port, :create_customer, @create_customer_reply)
    parrot(:finance_port, :create_invoice, @create_invoice_reply)
    parrot(:finance_port, :issue_invoice, @issue_invoice_reply)
    parrot(:finance_port, :create_cash_receipt, @create_cash_receipt_reply)
    parrot(:finance_port, :create_payment, @create_payment_reply)
  end

  defmodule SoftLedgerRepoParrot do
    use TestParrot
    parrot(:repo, :insert, {:ok, %{}})
    parrot(:repo, :delete, {:ok, %{}})
    parrot(:repo, :get, %{})
    parrot(:repo, :get_aggregate, %{})
    parrot(:repo, :get_by_app_count, %SoftLedgerTranslation{})
    parrot(:repo, :soft_ledger_account_id, %SoftLedgerTranslation{})
  end

  @deps %{
    rent_application_repo: GenericRepoParrot,
    finance_port: FinancePortParrot,
    softledger_repo: SoftLedgerRepoParrot
  }

  def line_items do
    account_id = 55555

    item01 = %{
      description: "Thing One",
      amount_in_cents: 100,
      account_id: account_id
    }

    item02 = %{
      description: "Thing Two",
      amount_in_cents: 200,
      account_id: account_id
    }

    [item01, item02]
  end

  def invoice_line_items(account_id) do
    item01 = %AppCount.Core.Ports.SoftLedgerBehaviour.InvoiceLineItem{
      description: "Thing One",
      unitAmount: "1.00",
      LedgerAccountId: account_id
    }

    item02 = %AppCount.Core.Ports.SoftLedgerBehaviour.InvoiceLineItem{
      description: "Thing Two",
      unitAmount: "2.00",
      LedgerAccountId: account_id
    }

    [item01, item02]
  end

  setup do
    random_num = Enum.random(10_000_000..99_999_999)

    account_params = %{
      name: UUID.uuid4(),
      number: "#{random_num}",
      natural_balance: "credit",
      type: "Asset",
      subtype: "Fixed Asset"
    }

    ~M[account_params]
  end

  describe "begin/1" do
    # TODO add tests for error conditions using Parrot for each
    # * finance_port.create_invoice(request, token)
    # * finance_port.issue_invoice(request, token)
    # * etc
    test "calls functions in pipline" do
      saga = %InvoiceSaga{}

      # When
      _saga = InvoiceSaga.begin(saga, InvoiceSagaParrot)

      assert_receive {:rent_application, _saga}
      assert_receive {:rent_payment, _saga}
      assert_receive {:validate_after_load, _saga}
      assert_receive {:create_customer_for_application, _saga}
      assert_receive {:add_items, _saga}
      assert_receive {:create_invoice, _saga}
      assert_receive {:issue_invoice, _saga}
      assert_receive {:create_cash_receipt, _saga}
      assert_receive {:create_payment, _saga}
      assert_receive {:log_errors, _saga}
      assert_receive {:publish_result, _saga}
    end
  end

  describe "rent_application" do
    setup do
      rent_application_id = 234
      ~M[rent_application_id]
    end

    test "success", ~M[rent_application_id] do
      person01 = %AppCount.RentApply.Person{status: "Occupant", full_name: "Occupant1"}
      person02 = %AppCount.RentApply.Person{status: "Occupant", full_name: "Occupant2"}

      lease_holder = %AppCount.RentApply.Person{
        status: "Lease Holder",
        full_name: "The Lease Holder"
      }

      SoftLedgerRepoParrot.say_get_aggregate(%AppCount.RentApply.RentApplication{
        id: rent_application_id,
        persons: [person01, person02, lease_holder]
      })

      saga = %InvoiceSaga{
        rent_application_id: rent_application_id,
        person_full_name: "Ringo Starr",
        deps: @deps
      }

      # When
      saga = InvoiceSaga.rent_application(saga)

      # Then
      assert ^rent_application_id = saga.rent_application_id
      assert_receive {:get_aggregate, _something}
    end

    test "add_items, success" do
      line_items = line_items()

      saga = %InvoiceSaga{
        line_items: line_items
      }

      # When
      %{invoice_line_items: invoice_line_items} = _saga = InvoiceSaga.add_items(saga)

      # Then
      assert invoice_line_items
      [first | _rest] = invoice_line_items
      assert %AppCount.Core.Ports.SoftLedgerBehaviour.InvoiceLineItem{} = first
    end
  end

  describe "validate" do
    setup do
      valid_saga = %InvoiceSaga{
        account_id: 435,
        app_count_struct: "AppCount.RentApply.RentApplication",
        app_count_id: 123,
        person_full_name: "Ringo Starr",
        soft_ledger_token: "WJSHWWJBHIGWHSJS&#U#HHJ..."
      }

      ~M[valid_saga]
    end

    test "ok", ~M[valid_saga] do
      saga = InvoiceSaga.validate_after_load(valid_saga)
      assert saga.error_message == ""
      assert saga.status != :error
    end

    test "missing account_id", ~M[valid_saga] do
      saga = %{valid_saga | account_id: nil}
      saga = InvoiceSaga.validate_after_load(saga)
      assert saga.status == :error
      assert saga.error_message == ~S[account_id: "can't be blank"]
    end

    test "missing app_count_struct", ~M[valid_saga] do
      saga = %{valid_saga | app_count_struct: :not_set}

      saga = InvoiceSaga.validate_after_load(saga)
      assert saga.error_message == ~S[app_count_struct: "is invalid"]
      assert saga.status == :error
    end

    test "missing app_count_id", ~M[valid_saga] do
      saga = %{valid_saga | app_count_id: :not_set}

      saga = InvoiceSaga.validate_after_load(saga)
      assert saga.error_message == ~S[app_count_id: "is invalid"]
      assert saga.status == :error
    end

    test "missing person_full_name", ~M[valid_saga] do
      saga = %{valid_saga | person_full_name: nil}

      saga = InvoiceSaga.validate_after_load(saga)
      assert saga.error_message == ~S[person_full_name: "can't be blank"]
      assert saga.status == :error
    end

    test "missing soft_ledger_token", ~M[valid_saga] do
      saga = %{valid_saga | soft_ledger_token: :not_set}

      saga = InvoiceSaga.validate_after_load(saga)
      assert saga.error_message == ~S[soft_ledger_token: "is invalid"]
      assert saga.status == :error
    end
  end

  describe "create_invoice account exists in DB" do
    setup %{account_params: account_params} do
      rent_application_id = 234
      {:ok, account} = AppCount.Finance.AccountRepo.insert(account_params)
      ~M[rent_application_id, account]
    end

    test "success", ~M[account, rent_application_id] do
      person01 = %AppCount.RentApply.Person{status: "Occupant", full_name: "Occupant1"}
      person02 = %AppCount.RentApply.Person{status: "Occupant", full_name: "Occupant2"}

      lease_holder = %AppCount.RentApply.Person{
        status: "Lease Holder",
        full_name: "The Lease Holder"
      }

      SoftLedgerRepoParrot.say_get_aggregate(%AppCount.RentApply.RentApplication{
        id: rent_application_id,
        persons: [person01, person02, lease_holder]
      })

      account_id = account.id
      customer_id = 123

      invoice_line_items = invoice_line_items(account_id)

      saga = %InvoiceSaga{
        customer_id: customer_id,
        invoice_line_items: invoice_line_items,
        soft_ledger_token: "A Token",
        deps: @deps
      }

      FinancePortParrot.say_create_invoice(
        {:ok, %CreateInvoiceResponse{_id: "Invoice From FinancePortParrot"}}
      )

      # When
      saga = InvoiceSaga.create_invoice(saga)

      # Then
      # Parrot call to SoftLedger port
      assert_receive {:create_invoice,
                      %AppCount.Core.Ports.SoftLedgerBehaviour.CreateInvoiceRequest{
                        ARAccountId: 10_855,
                        AgentId: 123,
                        InvoiceLineItems: [
                          %{
                            LedgerAccountId: _ledger_account_id1,
                            description: "Thing Two",
                            quantity: "1",
                            unitAmount: "2.00"
                          },
                          %{
                            LedgerAccountId: _ledger_account_id2,
                            description: "Thing One",
                            quantity: "1",
                            unitAmount: "1.00"
                          }
                        ],
                        LocationId: @parent_id,
                        currency: "USD"
                      }, "A Token"}

      assert saga.create_invoice_response
      assert saga.status == :invoice_created
    end

    test "error", ~M[account] do
      rent_application_id = 234

      person01 = %AppCount.RentApply.Person{status: "Occupant", full_name: "Occupant1"}
      person02 = %AppCount.RentApply.Person{status: "Occupant", full_name: "Occupant2"}

      lease_holder = %AppCount.RentApply.Person{
        status: "Lease Holder",
        full_name: "The Lease Holder"
      }

      SoftLedgerRepoParrot.say_get_aggregate(%AppCount.RentApply.RentApplication{
        id: rent_application_id,
        persons: [person01, person02, lease_holder]
      })

      account_id = account.id

      customer_id = 123
      invoice_line_items = invoice_line_items(account_id)

      saga = %InvoiceSaga{
        customer_id: customer_id,
        invoice_line_items: invoice_line_items,
        soft_ledger_token: "A Token",
        deps: @deps
      }

      FinancePortParrot.say_create_invoice({:error, "ERROR message"})

      log_messages =
        capture_log(fn ->
          # When
          saga = InvoiceSaga.create_invoice(saga)

          # Then

          assert saga.create_invoice_response
          assert saga.status == :error
        end)

      assert log_messages =~
               ~S<ERROR message" %AppCount.Core.Ports.SoftLedgerBehaviour.CreateInvoiceRequest{ARAccountId: 10855, AgentId: 123, InvoiceLineItems: [%{LedgerAccountId:>
    end
  end

  describe "issue_invoice" do
    setup do
      rent_application_id = 234
      ~M[rent_application_id]
    end

    test "input says error" do
      errored_saga = %InvoiceSaga{status: :error}
      saga = InvoiceSaga.issue_invoice(errored_saga)
      assert ^errored_saga = saga
    end

    test "input is :ok" do
      invoice_underscore_id = 8484

      saga = %InvoiceSaga{
        status: :invoice_created,
        invoice_underscore_id: invoice_underscore_id,
        soft_ledger_token: "A Token",
        deps: @deps
      }

      # When
      saga = InvoiceSaga.issue_invoice(saga)

      # Then
      # Parrot call to SoftLedger port
      assert_receive {:issue_invoice,
                      %AppCount.Core.Ports.SoftLedgerBehaviour.IssueInvoiceRequest{
                        id: ^invoice_underscore_id
                      }, "A Token"}

      assert saga.create_invoice_response
      assert saga.status == :invoice_issued
      assert saga.issue_invoice_response
    end
  end

  describe "create_cash_receipt" do
    setup do
      rent_application_id = 234
      ~M[rent_application_id]
    end

    test "input says error" do
      errored_saga = %{status: :error}
      saga = InvoiceSaga.create_cash_receipt(errored_saga)
      assert ^errored_saga = saga
    end

    test "input is :ok" do
      create_invoice_response = %CreateInvoiceResponse{_id: 2_112_122}

      saga = %InvoiceSaga{
        status: :invoice_issued,
        create_invoice_response: create_invoice_response,
        soft_ledger_token: "A Token",
        deps: @deps
      }

      # When
      saga = InvoiceSaga.create_cash_receipt(saga)

      # Then
      # Parrot call to SoftLedger port
      assert_receive {:create_cash_receipt,
                      %AppCount.Core.Ports.SoftLedgerBehaviour.CreateCashReceiptRequest{},
                      "A Token"}

      assert saga.create_cash_receipt_response
      assert saga.status == :cash_receipt_created
    end
  end

  describe "cash_receipt_request/1" do
    test "one" do
      response = %CreateInvoiceResponse{
        _id: 0,
        externalId: "externalId",
        type: "type",
        number: "type",
        status: "created",
        amount: "1.00",
        amountPayable: "1.00",
        url: "url",
        invoiceDate: "not_set",
        postedDate: "not_set",
        dueDate: "not_set",
        notes: "notes",
        attachments: [],
        reference: "reference",
        currency: "USD",
        SystemJobId: "SystemJobId",
        LocationId: 1111,
        ICLocationId: 0,
        AgentId: 2222,
        ShippingAddressId: 0,
        BillingAddressId: 0,
        ARAccountId: 10_855,
        TemplateId: 0,
        SalesOrderId: 0,
        InvoiceLineItems: []
      }

      result = InvoiceSaga.cash_receipt_request(response)

      today = Clock.today() |> to_string()

      assert %CreateCashReceiptRequest{
               AgentId: 2222,
               LocationId: 1111,
               amount: 1.0,
               currency: "USD",
               postingDate: ^today,
               receiveDate: ^today
             } = result
    end
  end

  describe "create_payment" do
    setup do
      rent_application_id = 234
      ~M[rent_application_id]
    end

    test "input says error" do
      errored_saga = %{status: :error}
      saga = InvoiceSaga.create_payment(errored_saga)
      assert ^errored_saga = saga
    end

    test "input is :ok" do
      create_invoice_response = %CreateInvoiceResponse{_id: 2_112_122}
      create_cash_receipt_response = %CreateCashReceiptResponse{_id: 12345}

      saga = %InvoiceSaga{
        status: :cash_receipt_created,
        create_invoice_response: create_invoice_response,
        create_cash_receipt_response: create_cash_receipt_response,
        soft_ledger_token: "A Token",
        deps: @deps
      }

      # When
      saga = InvoiceSaga.create_payment(saga)

      # Then
      # Parrot call to SoftLedger port
      assert_receive {:create_payment,
                      %AppCount.Core.Ports.SoftLedgerBehaviour.CreatePaymentRequest{}, "A Token"}

      assert saga.create_payment_response
      assert saga.status == :payment_created
    end
  end

  describe "create_payment_request/2" do
    test "one" do
      today = Clock.today() |> to_string()

      create_cash_receipt_response = %CreateCashReceiptResponse{
        _id: 0,
        number: "string",
        type: "string",
        amount: 1212,
        unused: 0,
        description: "not_set",
        attachments: [],
        currency: "USD",
        receiveDate: "2000-01-01",
        postingDate: "2000-01-01",
        status: "created",
        applyToInvoices: true,
        externalId: "string",
        AgentId: 0,
        LedgerAccountId: 0,
        LocationId: 0,
        UnappliedCashAccountId: 0
      }

      create_invoice_response = %CreateInvoiceResponse{
        _id: 0,
        externalId: "externalId",
        type: "type",
        number: "type",
        status: "created",
        amount: "1.00",
        amountPayable: "1.00",
        url: "url",
        invoiceDate: "not_set",
        postedDate: "not_set",
        dueDate: "not_set",
        notes: "notes",
        attachments: [],
        reference: "reference",
        currency: "USD",
        SystemJobId: "SystemJobId",
        LocationId: 1111,
        ICLocationId: 0,
        AgentId: 2222,
        ShippingAddressId: 0,
        BillingAddressId: 0,
        ARAccountId: 10_855,
        TemplateId: 0,
        SalesOrderId: 0,
        InvoiceLineItems: []
      }

      result =
        InvoiceSaga.create_payment_request(create_invoice_response, create_cash_receipt_response)

      assert %CreatePaymentRequest{
               InvoiceId: 0,
               LocationId: 1111,
               amount: 1.0,
               currency: "USD",
               paymentDate: ^today,
               type: "cashreceipt"
             } = result
    end
  end

  describe "publish_result" do
    setup do
      InvoiceSagaTopic.subscribe()
      rent_application_id = 234
      ~M[rent_application_id]
    end

    test ":error" do
      errored_saga = %InvoiceSaga{
        status: :error,
        app_count_struct: "AppCount.RentApply.RentApplication",
        app_count_id: 675
      }

      # When
      _saga = InvoiceSaga.publish_result(errored_saga)

      assert_receive %AppCount.Core.DomainEvent{
        content: %{status: :error},
        id: nil,
        inserted_at: nil,
        name: "completed",
        source: AppCount.Finance.InvoiceSaga,
        subject_id: 675,
        subject_name: "AppCount.RentApply.RentApplication",
        topic: "invoice_saga"
      }
    end

    # test ":ok" do
    #   create_invoice_response = %CreateInvoiceResponse{_id: 2_112_122}

    #   saga = %InvoiceSaga{
    #     status: :cash_receipt_created,
    #     create_invoice_response: create_invoice_response,
    #     soft_ledger_token: "A Token",
    #     deps: @deps
    #   }

    #   # When
    #   saga = InvoiceSaga.publish_result(saga)

    #   # Then
    #   # Parrot call to SoftLedger port
    #   assert_receive {:create_payment,
    #                   %AppCount.Core.Ports.SoftLedgerBehaviour.CreatePaymentRequest{}, "A Token"}

    #   assert saga.create_payment_response
    #   assert saga.status == :payment_created
    # end
  end

  test "log_errors :ok" do
    error_saga = %InvoiceSaga{
      status: :started
    }

    log_messages =
      capture_log(fn ->
        # When
        _saga = InvoiceSaga.log_errors(error_saga)
      end)

    assert log_messages == ""
  end

  test "log_errors errors" do
    error_saga = %InvoiceSaga{
      status: :error,
      soft_ledger_token: "WJSHWWJBHIGWHSJS&#U#HHJ..."
    }

    log_messages =
      capture_log(fn ->
        # When
        _saga = InvoiceSaga.log_errors(error_saga)
      end)

    assert log_messages =~ "[error] #AppCount.Finance.InvoiceSaga"
    assert log_messages =~ "status: :error"
    refute log_messages =~ "WJSHWWJBHIGWHSJS&#U#HHJ"
  end

  describe "add_error/2" do
    test "one" do
      saga = %InvoiceSaga{}
      mod_saga = InvoiceSaga.add_error(saga, "message one")
      assert mod_saga.status == :error
      assert mod_saga.error_message == "message one"
    end

    test "two" do
      saga = %InvoiceSaga{}

      mod_saga =
        saga
        |> InvoiceSaga.add_error("message one")
        |> InvoiceSaga.add_error("message two")

      assert mod_saga.status == :error
      assert mod_saga.error_message == "message one; message two"
    end
  end
end
