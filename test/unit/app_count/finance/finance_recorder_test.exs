defmodule AppCount.Finance.FinanceRecorderTest do
  @moduledoc false
  use AppCount.DataCase
  alias AppCount.Finance.FinanceRecorder
  alias AppCount.Core.DomainEvent
  alias AppCount.Finance.InvoiceSaga
  alias AppCount.Core.Ports.SoftLedgerBehaviour.OAuthResponse
  alias AppCount.Finance.SoftLedgerTranslation
  @parent_id AppCount.Adapters.SoftLedger.Config.load().parent_id

  use AppCount.Core.Ports.SoftLedgerBehaviour, :alias_requests_and_responses

  defmodule InvoceSagaParrot do
    use TestParrot
    parrot(:invoice_saga, :begin, %InvoiceSaga{})
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

    parrot(:finance_port, :fetch_token, {:ok, %OAuthResponse{access_token: "A-TOKEN"}})
    parrot(:finance_port, :create_location, @create_location_reply)
    parrot(:finance_port, :create_account, @create_account_reply)
    parrot(:finance_port, :update_account, @create_account_reply)
    parrot(:finance_port, :delete_account, {:ok, %{}})
    parrot(:finance_port, :create_customer, @create_customer_reply)
    parrot(:finance_port, :create_invoice, @create_invoice_reply)
  end

  # TODO potential GerericRepoParrot
  defmodule RepoParrot do
    use TestParrot
    parrot(:repo, :insert, {:ok, %{}})
    parrot(:repo, :delete, {:ok, %{}})
    parrot(:repo, :get, %{})
    parrot(:repo, :get_aggregate, %{})
    parrot(:repo, :get_by_app_count, %SoftLedgerTranslation{})
  end

  defmodule ProcessParrot do
    use TestParrot
    parrot(:process, :send_after, make_ref())
  end

  @deps %{
    invoice_saga: InvoceSagaParrot,
    finance_port: FinancePortParrot,
    softledger_repo: RepoParrot,
    rent_saga_repo: RepoParrot,
    tenant_repo: GenericRepoParrot,
    process: ProcessParrot
  }
  setup do
    [builder, property] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.get([:property])

    random_num = Enum.random(10_000_000..99_999_999)

    account_params = %{
      name: UUID.uuid4(),
      number: "#{random_num}",
      natural_balance: "credit",
      type: "Asset",
      subtype: "Fixed Asset"
    }

    ~M[builder, property, account_params]
  end

  test "handle_continue  " do
    state = %FinanceRecorder{deps: @deps}

    # When
    {:noreply, state} = FinanceRecorder.handle_continue(:init_accounting_server, state)

    # Then
    assert_receive :fetch_token
    assert state.soft_ledger_token
  end

  test "handle_info fetch_token" do
    state = %FinanceRecorder{deps: @deps}

    # When
    {:noreply, state} = FinanceRecorder.handle_info(:fetch_token, state)

    assert_receive :fetch_token
    assert state.soft_ledger_token == "A-TOKEN"
    assert %DateTime{} = state.prev_fetch_at
    assert %DateTime{} = state.next_fetch_at
  end

  test "schedule_next_token_fetch" do
    # When
    next_fetch_at = FinanceRecorder.schedule_next_token_fetch(ProcessParrot)

    my_pid = self()
    assert_receive {:send_after, ^my_pid, :fetch_token, 86_280_000}
    assert %DateTime{} = next_fetch_at
  end

  # ---------------------------------------------------------------  Property

  test "handle_info property_created", ~M[ property] do
    property_id = property.id
    property_id_string = "#{property.id}"

    domain_event = %DomainEvent{
      topic: "property",
      name: "property_created",
      content: %{property_id: property_id}
    }

    state = %FinanceRecorder{
      soft_ledger_token: "A Token",
      deps: @deps
    }

    # When
    {:noreply, _state} = FinanceRecorder.handle_info(domain_event, state)

    # Then
    property_name = property.name

    assert_receive {:create_location,
                    %CreateLocationRequest{
                      currency: "USD",
                      id: ^property_id_string,
                      name: ^property_name,
                      parent_id: @parent_id
                    }, "A Token"}

    # Parrot call to SoftLedger port
    assert_receive {:insert,
                    %{
                      soft_ledger_type: "Location",
                      soft_ledger_underscore_id: _soft_ledger_underscore_id,
                      app_count_struct: "AppCount.Properties.Property",
                      app_count_id: ^property_id
                    }}
  end

  # ---------------------------------------------------------------  Invoice
  describe "create_invoice/3" do
  end

  # ---------------------------------------------------------------  Account
  describe "handle_info account" do
    setup(%{account_params: account_params}) do
      {:ok, account} = AppCount.Finance.AccountRepo.insert(account_params)
      ~M[account]
    end

    test "created", ~M[account] do
      account_id = account.id

      domain_event = %DomainEvent{
        topic: "finance__accounts",
        name: "created",
        content: %{},
        subject_name: AppCount.Finance.Account,
        subject_id: account_id
      }

      state = %FinanceRecorder{
        soft_ledger_token: "A Token",
        deps: @deps
      }

      # When
      {:noreply, _state} = FinanceRecorder.handle_info(domain_event, state)

      # Then
      assert_receive {:create_account, %CreateUpdateAccountRequest{}, "A Token"}

      # Parrot call to SoftLedger port
      assert_receive {:insert,
                      %{
                        soft_ledger_type: "Account",
                        soft_ledger_underscore_id: "Ledger From FinancePortParrot",
                        app_count_struct: "AppCount.Finance.Account",
                        app_count_id: ^account_id
                      }}
    end

    test "changed", ~M[account] do
      account_id = account.id

      domain_event = %DomainEvent{
        topic: "finance__accounts",
        name: "changed",
        content: %{},
        subject_name: AppCount.Finance.Account,
        subject_id: account_id
      }

      state = %FinanceRecorder{
        soft_ledger_token: "A Token",
        deps: @deps
      }

      # When
      {:noreply, _state} = FinanceRecorder.handle_info(domain_event, state)

      # Then
      assert_receive {:update_account, %CreateUpdateAccountRequest{}, "A Token"}
    end

    test "deleted", ~M[account] do
      account_id = account.id

      domain_event = %DomainEvent{
        topic: "finance__accounts",
        name: "deleted",
        content: %{},
        subject_name: AppCount.Finance.Account,
        subject_id: account_id
      }

      state = %FinanceRecorder{
        soft_ledger_token: "A Token",
        deps: @deps
      }

      translation = %SoftLedgerTranslation{
        soft_ledger_type: "Account",
        soft_ledger_underscore_id: 999
      }

      RepoParrot.say_get_by_app_count(translation)

      # When
      {:noreply, _state} = FinanceRecorder.handle_info(domain_event, state)

      # Then
      assert_receive {:delete_account, %DeleteAccountRequest{}, "A Token"}
    end
  end

  # ---------------------------------------------------------------  Customer From Lease
  describe "handle_info customer from lease" do
    setup(%{builder: builder}) do
      [_builder, property, tenant, lease] =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease()
        |> PropBuilder.get([:property, :tenant, :lease])

      state = %FinanceRecorder{
        soft_ledger_token: "A Token",
        deps: @deps
      }

      ~M[property, tenant, lease, state]
    end

    test "created", ~M[ tenant, lease, state] do
      lease_id = lease.id
      tenant_id = tenant.id
      tenant_name = AppCount.Tenants.Tenant.full_name(tenant)

      domain_event = %DomainEvent{
        topic: "leases__leases",
        name: "created",
        content: %{tenant_id: tenant_id},
        subject_name: "AppCount.Leases.Lease",
        subject_id: lease_id,
        source: __MODULE__
      }

      RepoParrot.say_get(tenant)

      # When
      {:noreply, _state} = FinanceRecorder.handle_info(domain_event, state)

      # Then
      assert_receive {:get, ^tenant_id}
      assert_receive {:create_customer, %CreateCustomerRequest{name: ^tenant_name}, "A Token"}

      # Parrot call to SoftLedger port
      assert_receive {:insert,
                      %{
                        soft_ledger_type: "Customer",
                        soft_ledger_underscore_id: "Ledger From FinancePortParrot",
                        app_count_struct: "AppCount.Leases.Lease",
                        app_count_id: ^lease_id
                      }}
    end
  end

  # ---------------------------------------------------------------  Customer From Rental Payment
  describe "handle_info customer from rental payment" do
    setup(%{builder: builder}) do
      builder
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_lease()

      state = %FinanceRecorder{deps: @deps}

      ~M[state]
    end

    test "created", ~M[state] do
      rent_payment_id = 909

      domain_event = %DomainEvent{
        topic: "payments",
        name: "payment_recorded",
        content: %{
          rent_payment_id: rent_payment_id,
          line_items: [],
          account_id: 0
        }
      }

      # When
      {:noreply, _state} = FinanceRecorder.handle_info(domain_event, state)

      # Then
      assert_receive {:begin, stuff}

      assert stuff == %AppCount.Finance.InvoiceSaga{
               account_id: 0,
               customer_id: :not_set,
               deps: %{
                 softledger_repo: RepoParrot,
                 finance_port: FinancePortParrot,
                 rent_saga_repo: RepoParrot
               },
               invoice_line_items: [],
               line_items: [],
               rent_payment_id: rent_payment_id,
               soft_ledger_token: :not_set
             }
    end
  end

  # ---------------------------------------------------------------  Customer From Application
  describe "handle_info customer from application" do
    setup(%{builder: builder}) do
      builder
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_lease()

      state = %FinanceRecorder{deps: @deps}

      ~M[ state]
    end

    test "created", ~M[ state] do
      rent_application_id = 234

      domain_event = %DomainEvent{
        topic: "rent_apply__rent_applications",
        name: "created",
        content: %{account_id: 0, line_items: []},
        subject_id: rent_application_id,
        subject_name: "AppCount.RentApply.RentApplication",
        source: __MODULE__
      }

      # When
      {:noreply, _state} = FinanceRecorder.handle_info(domain_event, state)

      # Then
      assert_receive {:begin, stuff}

      assert stuff == %AppCount.Finance.InvoiceSaga{
               account_id: 0,
               customer_id: :not_set,
               deps: %{
                 softledger_repo: RepoParrot,
                 finance_port: FinancePortParrot
               },
               invoice_line_items: [],
               line_items: [],
               rent_application_id: rent_application_id,
               soft_ledger_token: :not_set
             }
    end
  end
end
