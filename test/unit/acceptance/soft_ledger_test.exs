defmodule AppCount.Acceptance.SoftLedgerTest do
  @moduledoc """
  CreatePropertyCreatesLocation

  -- TO RUN THIS TEST  --
  delete or (comment out) lines in config/test.exs for:

     tasker: AppCount.Support.Adapters.SkipTask
     pub_sub: AppCount.Support.Adapters.PubSubFake,
     softledger: AppCount.Support.Adapters.SoftLedgerFake

  THEN RUN Each test one at a time using line numbers



  * test All-In_One when Customer is a Rent-Application run
  mix test test/acceptance/soft_ledger_test.exs:182 --include acceptance_test  # passing
  * test Location create/delete
  mix test test/acceptance/soft_ledger_test.exs:322 --include acceptance_test  # passing
  * test Account create/delete
  mix test test/acceptance/soft_ledger_test.exs:287 --include acceptance_test  # passing
  * test Customer/Rent Application create/delete
  mix test test/acceptance/soft_ledger_test.exs:252 --include acceptance_test  #failing WIP)
  * test All-In_One when Customer is a Lease error
  mix test test/acceptance/soft_ledger_test.exs:382 --include acceptance_test # passing
  * test All-In_One when Customer is a Lease error but a little futher along
  mix test test/acceptance/soft_ledger_test.exs:452 --include acceptance_test # passing
  * test get_journal()
  mix test test/acceptance/soft_ledger_test.exs:566 --include acceptance_test # passing
  * test create_journal()
  mix test test/acceptance/soft_ledger_test.exs:594 --include acceptance_test # passing

  """
  use AppCount.Core.Ports.SoftLedgerBehaviour, :alias_requests_and_responses

  #  alias AppCount.Core.Ports.RequestSpec
  alias AppCount.Core.PropertyTopic
  alias AppCount.Core.DomainEvent
  alias AppCount.Finance.AccountRepo
  alias AppCount.Finance.SoftLedgerTranslationRepo
  alias AppCount.Adapters.SoftLedgerAdapter
  alias AppCount.Core.FinanceAccountTopic
  alias AppCount.Core.SoftLedgerTranslationTopic
  alias AppCount.Core.RentApplicationTopic
  alias AppCount.Core.InvoiceSagaTopic
  alias AppCount.Finance.InvoiceSaga

  use AppCount.DataCase
  @moduletag :acceptance_test

  def create_lease_with_payment do
    dates =
      AppTime.new()
      |> AppTime.plus_to_date(:yesterday, days: -1)
      |> AppTime.plus_to_date(:tomorrow, days: 1)
      |> AppTime.times()

    [_builder, unit, tenant, payment] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_payment()
      |> PropBuilder.get([:unit, :tenant, :payment])

    customer_params = %{
      tenant_id: tenant.id,
      start_date: dates.yesterday,
      end_date: dates.tomorrow,
      unit_id: unit.id
    }

    # Create
    {:ok, %{lease: lease}} = AppCount.Leases.Utils.Leases.create_lease(customer_params)
    lease_id = lease.id

    assert_receive %DomainEvent{
                     name: "created",
                     topic: "soft_ledger__translations",
                     subject_name: "AppCount.Leases.Lease",
                     subject_id: ^lease_id
                   },
                   4000

    assert %{soft_ledger_type: "Customer", soft_ledger_underscore_id: soft_ledger_customer_id} =
             SoftLedgerTranslationRepo.get_by_app_count("AppCount.Leases.Lease", lease_id)

    {lease, soft_ledger_customer_id, payment.id}
  end

  def create_account_with_data do
    subscribe(SoftLedgerTranslationTopic)

    random_num = Enum.random(10_000_000..99_999_999)

    account_params = %{
      name: UUID.uuid4(),
      number: "#{random_num}",
      natural_balance: "credit",
      type: "Asset",
      subtype: "Fixed Asset"
    }

    # When Create
    result = AccountRepo.insert(account_params)
    assert {:ok, account} = result

    account_id = account.id

    assert_receive %DomainEvent{
                     name: "created",
                     topic: "soft_ledger__translations",
                     subject_name: "AppCount.Finance.Account",
                     subject_id: ^account_id
                   },
                   4000

    result_account =
      SoftLedgerTranslationRepo.get_by_app_count("AppCount.Finance.Account", account_id)

    assert %{soft_ledger_type: "Account", soft_ledger_underscore_id: soft_ledger_account_id} =
             result_account

    {account, soft_ledger_account_id}
  end

  def begin_for_application(account_id, rent_application_id) do
    {:ok, o_auth_response} = SoftLedgerAdapter.fetch_token()

    # in prod these should be different accounts
    item01_account_id = account_id
    item02_account_id = account_id
    invoice_account_id = account_id

    item01 = %{
      description: "Thing One",
      account_id: item01_account_id,
      amount_in_cents: 100
    }

    item02 = %{
      description: "Thing Two",
      account_id: item02_account_id,
      amount_in_cents: 200
    }

    items = [item01, item02]

    invoice_saga = %InvoiceSaga{
      line_items: items,
      account_id: invoice_account_id,
      soft_ledger_token: o_auth_response.access_token,
      rent_application_id: rent_application_id
    }

    # When
    saga = AppCount.Finance.InvoiceSaga.begin(invoice_saga)

    saga
  end

  describe "All-In_One when Customer is a Rent-Application" do
    setup do
      [_builder, rent_application] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_rent_application()
        |> PropBuilder.add_person()
        |> PropBuilder.add_tenant()
        |> PropBuilder.get([:rent_application])

      ~M[rent_application]
    end

    test "run", ~M[rent_application] do
      subscribe(InvoiceSagaTopic)
      rent_application_id = rent_application.id

      # When create account
      {account, _soft_ledger_account_id} = create_account_with_data()

      _invoice_saga =
        begin_for_application(
          account.id,
          rent_application.id
        )

      assert_receive %AppCount.Core.DomainEvent{
        content: %{status: :payment_created},
        id: nil,
        inserted_at: nil,
        name: "completed",
        source: AppCount.Finance.InvoiceSaga,
        subject_id: ^rent_application_id,
        subject_name: "AppCount.RentApply.RentApplication",
        topic: "invoice_saga"
      }
    end
  end

  def post_delete_customer(soft_ledger_underscore_id) do
    # Needs to be low level since we do not delete customers in the production code
    # Delete Customer in SoftLedger
    del_request = %DeleteCustomerRequest{id: soft_ledger_underscore_id}
    {:ok, o_auth_response} = SoftLedgerAdapter.fetch_token()

    request_spec =
      SoftLedgerAdapter.request_spec(
        request: del_request,
        token: o_auth_response.access_token
      )

    {:ok, "successfully deleted"} = SoftLedgerAdapter.delete_customer(request_spec)
  end

  describe "Customer/Rent Application" do
    setup do
      [_builder, rent_application] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_rent_application()
        |> PropBuilder.add_person()
        |> PropBuilder.add_tenant()
        |> PropBuilder.get([:rent_application])

      ~M[rent_application]
    end

    test "create/delete", ~M[rent_application] do
      subscribe(SoftLedgerTranslationTopic)
      subscribe(RentApplicationTopic)

      rent_application_id = rent_application.id

      assert AppCount.Core.RentApplicationRepo.get_aggregate(rent_application.id)

      # When Publish after create
      result =
        AppCount.RentApply.Utils.RentApplications.publish_application_created(
          {:ok, %{application: rent_application}}
        )

      # Then
      assert {:ok, %{application: _application}} = result

      # Consume event that PropBuilder caused
      assert_receive %DomainEvent{
                       name: "created",
                       topic: "soft_ledger__translations",
                       subject_id: _property_id,
                       subject_name: "AppCount.Properties.Property"
                     },
                     4000

      # Then
      assert_receive %DomainEvent{
                       name: "created",
                       topic: "rent_apply__rent_applications",
                       subject_name: "AppCount.RentApply.RentApplication",
                       subject_id: ^rent_application_id
                     },
                     4000

      # Cleanup SoftLedger
      # Needs to be low level since we do not delete customers in the production code
      # Delete Customer in SoftLedger

      # Test won't succeed until we start provide items with accounts for recording the rent_application

      assert %{soft_ledger_type: "Customer", soft_ledger_underscore_id: soft_ledger_underscore_id} =
               SoftLedgerTranslationRepo.get_by_app_count(
                 "AppCount.RentApply.RentApplication",
                 rent_application_id
               )

      post_delete_customer(soft_ledger_underscore_id)
    end
  end

  describe "Account" do
    test "create/delete" do
      subscribe(FinanceAccountTopic)
      subscribe(SoftLedgerTranslationTopic)

      # When Create
      {account, _soft_ledger_account_id} = create_account_with_data()

      # Then
      assert_receive created_event = %DomainEvent{name: "created", topic: "finance__accounts"}
      assert created_event.subject_id == account.id

      # When deleted
      AccountRepo.delete(account.id)

      # # Then
      # # it was deleted in DB
      assert_receive %DomainEvent{name: "deleted", topic: "finance__accounts"}

      # # it was deleted in SoftLedger Adapter
      assert_receive %DomainEvent{name: "deleted", topic: "soft_ledger__translations"}, 4000
    end
  end

  describe "Location" do
    setup do
      subscribe(PropertyTopic)
      subscribe(SoftLedgerTranslationTopic)

      [_builder, property] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.get([:property])

      ~M[property]
    end

    test "create/delete", ~M[property] do
      property_id = property.id

      assert_receive _event = %DomainEvent{
                       content: %{property_id: ^property_id},
                       name: "property_created",
                       source: AppCount.Properties.PropertyRepo,
                       subject_id: nil,
                       subject_name: nil,
                       topic: "property"
                     }

      assert_receive %AppCount.Core.DomainEvent{
                       content: %{},
                       name: "created",
                       source: AppCount.Finance.SoftLedgerTranslationRepo,
                       subject_id: actual_property_id,
                       subject_name: "AppCount.Properties.Property",
                       topic: "soft_ledger__translations"
                     },
                     6000

      assert actual_property_id == property_id

      # delete Location in SoftLedger
      result =
        SoftLedgerTranslationRepo.get_by_app_count("AppCount.Properties.Property", property_id)

      assert %{soft_ledger_type: "Location", soft_ledger_underscore_id: soft_ledger_underscore_id} =
               result

      del_request = %DeleteLocationRequest{id: soft_ledger_underscore_id}
      {:ok, o_auth_response} = SoftLedgerAdapter.fetch_token()

      request_spec =
        SoftLedgerAdapter.request_spec(
          request: del_request,
          token: o_auth_response.access_token
        )

      {:ok, _message} = SoftLedgerAdapter.delete_location(request_spec)
    end
  end

  describe "All-In_One when Customer is a Lease" do
    test "error" do
      subscribe(FinanceAccountTopic)
      subscribe(SoftLedgerTranslationTopic)
      subscribe(AppCount.Core.LeaseTopic)
      subscribe(AppCount.Core.InvoiceSagaTopic)

      {lease, soft_ledger_customer_id, payment_id} = create_lease_with_payment()

      item01 = %{
        description: "Thing One",
        amount_in_cents: 1200,
        account_id: 123
      }

      item02 = %{
        description: "Thing Two",
        amount_in_cents: 1200,
        account_id: 456
      }

      line_items = [item01, item02]

      content = %{
        line_items: line_items,
        account_id: 34_243_343,
        rent_payment_id: payment_id
      }

      # When
      AppCount.Core.PaymentTopic.payment_recorded(content, __MODULE__)

      # Then
      lease_id = lease.id

      assert_receive %DomainEvent{
                       name: "created",
                       topic: "leases__leases",
                       subject_id: ^lease_id
                     },
                     4000

      assert_receive %AppCount.Core.DomainEvent{
        content: %{},
        id: nil,
        inserted_at: nil,
        name: "created",
        source: AppCount.Finance.SoftLedgerTranslationRepo,
        subject_name: "AppCount.Properties.Property",
        topic: "soft_ledger__translations"
      }

      %AppCount.Core.DomainEvent{
        content: %{status: :error},
        id: nil,
        inserted_at: nil,
        name: "completed",
        source: AppCount.Finance.InvoiceSaga,
        subject_id: nil,
        subject_name: :not_set,
        topic: "invoice_saga"
      }

      #  Error log
      #
      #    2021-05-17 16:48:45.879 [error] create_invoice "400 Bad Request"
      # %AppCount.Core.Ports.SoftLedgerBehaviour.CreateInvoiceRequest{
      #   ARAccountId: nil,
      #   AgentId: 6013,
      #   InvoiceLineItems: [
      #     %{LedgerAccountId: nil, description: "Thing Two", quantity: "1", unitAmount: "12.00"},
      #     %{LedgerAccountId: nil, description: "Thing One", quantity: "1", unitAmount: "12.00"}
      #   ],
      #   LocationId: 876,
      #   currency: "USD"
      # }

      post_delete_customer(soft_ledger_customer_id)
    end

    test "error but a little futher along" do
      subscribe(FinanceAccountTopic)
      subscribe(SoftLedgerTranslationTopic)
      subscribe(AppCount.Core.LeaseTopic)
      subscribe(AppCount.Core.InvoiceSagaTopic)

      {lease, soft_ledger_customer_id, payment_id} = create_lease_with_payment()

      item01_account_id = 123
      item02_account_id = 456
      # numbers was taken from SoftLedger sandbox UI
      sandbox_account_id = AppCount.Adapters.SoftLedger.Config.load().ar_account_id

      item01 = %{
        description: "Thing One",
        amount_in_cents: 1200,
        account_id: item01_account_id
      }

      {:ok, _translation} =
        %{
          soft_ledger_type: "Account",
          soft_ledger_underscore_id: sandbox_account_id,
          app_count_struct: "AppCount.Finance.Account",
          app_count_id: item01_account_id
        }
        |> SoftLedgerTranslationRepo.insert()

      item02 = %{
        description: "Thing Two",
        amount_in_cents: 1200,
        account_id: item02_account_id
      }

      {:ok, _translation} =
        %{
          soft_ledger_type: "Account",
          soft_ledger_underscore_id: sandbox_account_id,
          app_count_struct: "AppCount.Finance.Account",
          app_count_id: item02_account_id
        }
        |> SoftLedgerTranslationRepo.insert()

      line_items = [item01, item02]

      content = %{
        line_items: line_items,
        account_id: 34_243_343,
        rent_payment_id: payment_id
      }

      # When
      AppCount.Core.PaymentTopic.payment_recorded(content, __MODULE__)

      # Then
      lease_id = lease.id

      assert_receive %DomainEvent{
                       name: "created",
                       topic: "leases__leases",
                       # TODO why is this not a string?
                       source: AppCount.Leases.Utils.Leases,
                       subject_id: ^lease_id
                     },
                     4000

      assert_receive %AppCount.Core.DomainEvent{
                       name: "created",
                       source: AppCount.Finance.SoftLedgerTranslationRepo,
                       subject_id: ^item01_account_id,
                       subject_name: "AppCount.Finance.Account",
                       topic: "soft_ledger__translations"
                     },
                     4000

      assert_receive %AppCount.Core.DomainEvent{
                       name: "created",
                       source: AppCount.Finance.SoftLedgerTranslationRepo,
                       subject_id: ^item02_account_id,
                       subject_name: "AppCount.Finance.Account",
                       topic: "soft_ledger__translations"
                     },
                     4000

      assert_receive %AppCount.Core.DomainEvent{
                       name: "created",
                       source: AppCount.Finance.SoftLedgerTranslationRepo,
                       subject_name: "AppCount.Properties.Property",
                       topic: "soft_ledger__translations"
                     },
                     4000

      assert_receive %AppCount.Core.DomainEvent{
                       name: "created",
                       source: AppCount.Finance.SoftLedgerTranslationRepo,
                       subject_name: "AppCount.Ledgers.Payment",
                       topic: "soft_ledger__translations"
                     },
                     4000

      # Then InvoiceSaga tells us that it has completed successfully
      assert_receive %AppCount.Core.DomainEvent{
                       content: %{status: :payment_created},
                       id: nil,
                       inserted_at: nil,
                       name: "completed",
                       source: AppCount.Finance.InvoiceSaga,
                       subject_id: ^payment_id,
                       subject_name: "AppCount.Ledgers.Payment",
                       topic: "invoice_saga"
                     },
                     4000

      post_delete_customer(soft_ledger_customer_id)
    end
  end

  describe "adapter testing" do
    test "SoftLedgerAdapter.get_journal()" do
      alias AppCount.Core.Ports.RequestSpec
      alias AppCount.Core.Ports.SoftLedgerBehaviour.GetJournalResponse.Data

      {:ok, o_auth_response} = SoftLedgerAdapter.fetch_token()
      get_request = %GetJournalRequest{}

      request_spec = %RequestSpec{
        request: get_request,
        token: o_auth_response.access_token,
        adapter: SoftLedgerAdapter
      }

      # When
      {:ok, result} = SoftLedgerAdapter.get_journal(request_spec)

      # Then
      assert %GetJournalResponse{} = result
      [first | _rest] = result.data

      assert %Data{} = first
    end

    test "SoftLedgerAdapter.create_journal()" do
      alias AppCount.Core.Ports.RequestSpec

      sandbox_account_id = AppCount.Adapters.SoftLedger.Config.load().ar_account_id
      location_id = AppCount.Adapters.SoftLedger.Config.load().parent_id

      {:ok, o_auth_response} = SoftLedgerAdapter.fetch_token()

      debit_transaction = %CreateJournalTransactionRequest{
        transactionDate: "2021-06-08",
        postedDate: "2021-06-08",
        debit: "5",
        credit: "0",
        LocationId: location_id,
        LedgerAccountId: sandbox_account_id
      }

      credit_transaction = %CreateJournalTransactionRequest{
        transactionDate: "2021-06-08",
        postedDate: "2021-06-08",
        debit: "0",
        credit: "5",
        LocationId: location_id,
        LedgerAccountId: sandbox_account_id
      }

      get_request =
        %{
          status: "draft",
          entryType: "Standard",
          sourceLedger: "AR",
          reference: "What the heck is a reference?",
          currency: "USD",
          transactions: [debit_transaction, credit_transaction]
        }
        |> CreateJournalRequest.new()

      request_spec = %RequestSpec{
        request: get_request,
        token: o_auth_response.access_token,
        adapter: SoftLedgerAdapter
      }

      # When
      {:ok, result} = SoftLedgerAdapter.create_journal(request_spec)

      # Then
      assert %CreateJournalResponse{_id: underscore_id} = result

      # Now we do a bit of clean up
      del_request = %DeleteJournalRequest{id: underscore_id}
      {:ok, o_auth_response} = SoftLedgerAdapter.fetch_token()

      request_spec =
        SoftLedgerAdapter.request_spec(
          request: del_request,
          token: o_auth_response.access_token
        )

      {:ok, _message} = SoftLedgerAdapter.delete_journal(request_spec)
    end
  end
end
