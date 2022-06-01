defmodule AppCount.Finance.FinanceRecorder do
  @moduledoc """
  FinanceRecorder listend for events that are interesting to the Accounting subsystem.
  When a Property is created it calls the FinancePort.create_location()
  which uses the SoftLedgerAdapter to message the SoftLedger internet service

  When successful the SoftLedgerAdapter returns a Response struct that contains a field named `_id`
  This is SoftLedger's key to the object in the SoftLedger system.any()
  We store the `_id` into the SoftLedgertranslations DB table along with the AppCount struct and id to which it belongs.

  """
  use GenServer
  require Logger
  alias AppCount.Finance.FinanceRecorder
  alias AppCount.Finance.Account
  alias AppCount.Core.DomainEvent
  alias AppCount.Finance.SoftLedgerTranslation
  alias AppCount.Finance.InvoiceSaga
  use AppCount.Core.Ports.SoftLedgerBehaviour, :alias_requests_and_responses

  # deps
  alias AppCount.Core.Ports.FinancePort
  alias AppCount.Finance.SoftLedgerTranslationRepo
  alias AppCount.Tenants.TenantRepo
  alias AppCount.Finance.AccountRepo
  alias AppCount.Core.Clock
  alias AppCount.Core.RentApplicationRepo

  @deps %{
    invoice_saga: AppCount.Finance.InvoiceSaga,
    rent_saga_repo: RentSagaRepo,
    finance_port: FinancePort,
    softledger_repo: SoftLedgerTranslationRepo,
    tenant_repo: TenantRepo,
    process: Process,
    rent_application_repo: RentApplicationRepo
  }

  @account_struct_name "AppCount.Finance.Account"
  @using_soft_ledger AppCount.Core.FeatureFlags.load().using_soft_ledger

  defstruct soft_ledger_token: :not_set,
            prev_fetch_at: :not_set,
            next_fetch_at: :not_set,
            deps: @deps

  # ---------  Client Interface  -------------

  def start_link([]) do
    start_link(name: __MODULE__)
  end

  def start_link(name: name) do
    GenServer.start_link(__MODULE__, name: name)
  end

  # ---------  Server  -------------

  def init(_) do
    AppCount.GenserverLogger.starting(__MODULE__, "Global")
    AppCount.Core.PropertyTopic.subscribe()
    AppCount.Core.FinanceAccountTopic.subscribe()
    AppCount.Core.LeaseTopic.subscribe()
    AppCount.Core.RentApplicationTopic.subscribe()
    AppCount.Core.PaymentTopic.subscribe()

    state = %FinanceRecorder{}
    {:ok, state, {:continue, :init_accounting_server}}
  end

  # ===========================================================  handle_continue
  def handle_continue(:init_accounting_server, %FinanceRecorder{} = state) do
    state = fetch_token_into_state(state)
    {:noreply, state}
  end

  # ===========================================================   handle_info

  def handle_info(:fetch_token, %FinanceRecorder{} = state) do
    state = fetch_token_into_state(state)
    {:noreply, state}
  end

  # ----------------------------------------------------------   TOPIC: "leases__leases"
  def handle_info(
        %DomainEvent{
          topic: "leases__leases",
          name: "created",
          content: %{tenant_id: tenant_id},
          subject_name: "AppCount.Leases.Lease",
          subject_id: lease_id
        },
        %FinanceRecorder{} = state
      ) do
    state =
      state
      |> create_customer_for_lease(lease_id, tenant_id)

    {:noreply, state}
  end

  # ----------------------------------------------------------   TOPIC: "payments"
  def handle_info(
        # TODO: WE need this to return account_id as well as line items. PaymentTopic only returns
        # rent saga id at the moment
        %DomainEvent{
          topic: "payments",
          name: "payment_recorded",
          content: %{
            rent_payment_id: rent_payment_id,
            line_items: line_items,
            account_id: account_id
          }
        },
        %FinanceRecorder{
          soft_ledger_token: token,
          deps: %{invoice_saga: invoice_saga_module} = deps
        } = state
      ) do
    saga_deps = deps |> Map.take([:finance_port, :softledger_repo, :rent_saga_repo])

    saga = %InvoiceSaga{
      rent_payment_id: rent_payment_id,
      account_id: account_id,
      line_items: line_items,
      soft_ledger_token: token,
      deps: saga_deps
    }

    if @using_soft_ledger do
      _saga = invoice_saga_module.begin(saga)
    end

    {:noreply, state}
  end

  # ----------------------------------------------------------   TOPIC: "rent_apply__rent_applications"
  def handle_info(
        %DomainEvent{
          topic: "rent_apply__rent_applications",
          name: "created",
          content: %{
            account_id: account_id,
            line_items: line_items
          },
          subject_id: rent_application_id,
          subject_name: "AppCount.RentApply.RentApplication"
        },
        %FinanceRecorder{
          soft_ledger_token: token,
          deps: %{invoice_saga: invoice_saga_module} = deps
        } = state
      ) do
    saga_deps = deps |> Map.take([:finance_port, :softledger_repo, :rent_application_repo])

    saga = %InvoiceSaga{
      rent_application_id: rent_application_id,
      account_id: account_id,
      line_items: line_items,
      soft_ledger_token: token,
      deps: saga_deps
    }

    if @using_soft_ledger do
      # MAYBE:  Task.start()
      _saga = invoice_saga_module.begin(saga)
    end

    {:noreply, state}
  end

  # ----------------------------------------------------------   TOPIC: "property"

  def handle_info(
        %DomainEvent{
          topic: "property",
          name: "property_created",
          # TODO move to subject_id
          content: %{property_id: property_id}
        },
        %FinanceRecorder{} = state
      ) do
    state = property_created(state, property_id)
    {:noreply, state}
  end

  # ----------------------------------------------------------   TOPIC: "finance__accounts"

  def handle_info(
        %DomainEvent{
          topic: "finance__accounts",
          name: "created",
          subject_name: AppCount.Finance.Account,
          subject_id: account_id,
          content: %{}
        },
        %FinanceRecorder{} = state
      ) do
    state = account_created(state, account_id)
    {:noreply, state}
  end

  def handle_info(
        %DomainEvent{
          topic: "finance__accounts",
          name: "changed",
          subject_name: AppCount.Finance.Account,
          subject_id: account_id,
          content: %{}
        },
        %FinanceRecorder{} = state
      ) do
    state = account_changed(state, account_id)
    {:noreply, state}
  end

  def handle_info(
        %DomainEvent{
          topic: "finance__accounts",
          name: "deleted",
          subject_name: AppCount.Finance.Account,
          subject_id: account_id,
          content: %{}
        },
        %FinanceRecorder{} = state
      ) do
    state = account_deleted(state, account_id)
    {:noreply, state}
  end

  def handle_info(%DomainEvent{} = other, %FinanceRecorder{} = state) do
    # pass thru
    "FinanceRecorder received unexpected message: #{inspect(other)}"
    |> Logger.warn()

    {:noreply, state}
  end

  #  -----------------------------------------------------------  implementation

  defp create_customer_for_lease(
         %FinanceRecorder{
           soft_ledger_token: token,
           deps: %{
             finance_port: finance_port,
             softledger_repo: softledger_repo,
             tenant_repo: tenant_repo
           }
         } = state,
         lease_id,
         lease_holder_tenant_id
       ) do
    name =
      lease_holder_tenant_id
      |> tenant_repo.get()
      |> AppCount.Tenants.Tenant.full_name()

    request = CreateCustomerRequest.new(%{name: name})

    case finance_port.create_customer(request, token) do
      {:ok, %CreateCustomerResponse{_id: underscore_id}} ->
        softledger_repo.insert(%{
          soft_ledger_type: "Customer",
          soft_ledger_underscore_id: underscore_id,
          app_count_struct: "AppCount.Leases.Lease",
          app_count_id: lease_id
        })

      {:error, message} ->
        "#{inspect(message)} #{inspect(request)}"
        |> Logger.error()
    end

    state
  end

  defp property_created(
         %FinanceRecorder{
           soft_ledger_token: token,
           deps: %{
             finance_port: finance_port,
             softledger_repo: softledger_repo
           }
         } = state,
         property_id
       ) do
    property = AppCount.Properties.PropertyRepo.get(property_id)

    request = CreateLocationRequest.new(%{id: "#{property.id}", name: property.name})

    # returns "Location From SoftLedger"
    case finance_port.create_location(request, token) do
      {:ok, %CreateLocationResponse{id: _location_id, _id: underscore_id}} ->
        softledger_repo.insert(%{
          soft_ledger_type: "Location",
          soft_ledger_underscore_id: underscore_id,
          app_count_struct: "AppCount.Properties.Property",
          app_count_id: property_id
        })

      {:error, message} ->
        "#{inspect(message)} #{inspect(request)}"
        |> Logger.error()
    end

    state
  end

  defp account_created(
         %FinanceRecorder{
           soft_ledger_token: token,
           deps: %{
             finance_port: finance_port
           }
         } = state,
         account_id
       ) do
    {:ok, account} = AccountRepo.aggregate(account_id)

    request = new_create_update_request(account)

    case finance_port.create_account(request, token) do
      {:ok, %{_id: underscore_id}} ->
        softledger_repo_insert(
          state,
          account_id,
          underscore_id,
          request
        )

      {:error, message} ->
        "#{inspect(message)} #{inspect(request)}"
        |> Logger.error()
    end

    state
  end

  def softledger_repo_insert(
        %FinanceRecorder{
          deps: %{
            softledger_repo: softledger_repo
          }
        },
        account_id,
        underscore_id,
        request
      ) do
    case softledger_repo.insert(%{
           soft_ledger_type: "Account",
           soft_ledger_underscore_id: underscore_id,
           app_count_struct: @account_struct_name,
           app_count_id: account_id
         }) do
      {:ok, translation} ->
        {:ok, translation}

      {:error, message} ->
        "#{inspect(message)} #{inspect(request)}"
        |> Logger.error()

        {:error, message}
    end
  end

  defp account_changed(
         %FinanceRecorder{
           soft_ledger_token: token,
           deps: %{
             finance_port: finance_port
           }
         } = state,
         account_id
       ) do
    {:ok, account} = AccountRepo.aggregate(account_id)

    request = new_create_update_request(account)

    case finance_port.update_account(request, token) do
      {:ok, response} ->
        # TODO what do we do here?
        {:ok, response}

      {:error, message} ->
        "#{inspect(message)} #{inspect(request)}"
        |> Logger.error()
    end

    state
  end

  def new_create_update_request(%Account{} = account) do
    CreateUpdateAccountRequest.new(%{
      name: account.name,
      naturalBalance: account.natural_balance,
      number: account.number,
      type: account.type,
      subtype: "subtype"
    })
  end

  defp account_deleted(
         %FinanceRecorder{
           soft_ledger_token: token,
           deps: %{
             finance_port: finance_port,
             softledger_repo: softledger_repo
           }
         } = state,
         account_id
       ) do
    case softledger_repo.get_by_app_count(@account_struct_name, account_id) do
      nil ->
        state

      translation ->
        {_type, underscore_id} = SoftLedgerTranslation.softledger_id(translation)
        request = %DeleteAccountRequest{id: underscore_id}

        finance_port.delete_account(request, token)
        softledger_repo.delete(translation.id)
        state
    end
  end

  defp fetch_token_into_state(
         %FinanceRecorder{deps: %{finance_port: finance_port, process: process}} = state
       ) do
    {:ok, %OAuthResponse{access_token: token}} = finance_port.fetch_token()

    schedule_next_token_fetch(process)
    |> time_stamp(state)
    |> Map.put(:soft_ledger_token, token)
  end

  def schedule_next_token_fetch(process \\ Process) do
    interval_in_milliseconds = almost_a_day_in_seconds() * 1000

    process.send_after(self(), :fetch_token, interval_in_milliseconds)
    Clock.now({almost_a_day_in_seconds(), :seconds})
    # return next_fetch_at
  end

  def almost_a_day_in_seconds() do
    day_in_seconds = 24 * 60 * 60
    day_in_seconds - 120
  end

  def time_stamp(next_fetch_at, state) do
    state
    |> Map.put(:prev_fetch_at, Clock.now())
    |> Map.put(:next_fetch_at, next_fetch_at)
  end
end
