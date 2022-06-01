defmodule AppCount.Finance.InvoiceSaga do
  @moduledoc """
  Create Invoice
  Issue Invoice
  Create Cash Receipt for Customer
  Create a Payment with the Invoice

  In the Error condition the state of the saga is set to status: :error

  The only valid FSM status-states and transitions are:
  :started --> :invoice_created --> :invoice_issued --> :cash_receipt_created --> :payment_created
          \-> :error            \-> :error         \-> :error                \-> :error
  """
  use AppCount.Core.Ports.SoftLedgerBehaviour, :alias_requests_and_responses
  use Ecto.Schema
  import Ecto.Changeset

  # When IO.inspect() do not show :soft_ledger_token, makes it readable
  @derive {Inspect, except: [:soft_ledger_token, :line_items, :deps]}

  alias AppCount.Finance.Money
  alias AppCount.RentApply.RentApplication
  alias AppCount.Finance.SoftLedgerTranslationRepo
  alias AppCount.Finance.InvoiceSaga
  alias AppCount.Core.InvoiceSagaTopic

  @deps %{
    finance_port: AppCount.Core.Ports.FinancePort,
    softledger_repo: SoftLedgerTranslationRepo,
    rent_application_repo: AppCount.Core.RentApplicationRepo
  }

  require Logger

  embedded_schema do
    field(:status, :string, default: :started)
    field(:error_message, :string, default: "")
    # needs either: rent_application_id or rent_payment_id
    field(:rent_application_id, :string, default: :not_set)
    field(:rent_payment_id, :string, default: :not_set)
    field(:account_id, :integer)
    field(:app_count_struct, :string, default: :not_set)
    field(:app_count_id, :integer, default: nil)
    field(:person_full_name, :string)
    field(:customer_id, :string, default: :not_set)
    field(:invoice_underscore_id, :string, default: :not_set)
    field(:line_items, :string, default: [])
    field(:invoice_line_items, :string, default: [])
    field(:soft_ledger_token, :string)
    field(:create_invoice_response, :string, default: :not_set)
    field(:issue_invoice_response, :string, default: :not_set)
    field(:create_cash_receipt_response, :string, default: :not_set)
    field(:create_payment_response, :string, default: :not_set)
    field(:deps, :string, default: @deps)
  end

  @required_after_load [
    :account_id,
    :person_full_name,
    :soft_ledger_token,
    :app_count_id,
    :app_count_struct
  ]

  def after_load_changeset(params) do
    %__MODULE__{}
    |> cast(params, @required_after_load)
    |> validate_required(@required_after_load)
  end

  def begin(%InvoiceSaga{} = saga, saga_module \\ InvoiceSaga) do
    saga =
      saga
      |> saga_module.rent_application()
      |> saga_module.rent_payment()
      |> saga_module.validate_after_load()
      |> saga_module.create_customer_for_application()
      |> saga_module.add_items()
      |> saga_module.create_invoice()
      |> saga_module.issue_invoice()
      |> saga_module.create_cash_receipt()
      |> saga_module.create_payment()
      |> saga_module.log_errors()
      |> saga_module.publish_result()

    saga
  end

  # this sets up for the one time rental application
  # skip since without a rent_application_id, this must be a monthy rent payment
  def rent_application(%{rent_application_id: :not_set} = saga) do
    saga
  end

  # this sets up for the one time rental application
  def rent_application(
        %InvoiceSaga{
          status: :started,
          rent_application_id: rent_application_id,
          rent_payment_id: :not_set,
          deps: %{
            rent_application_repo: rent_application_repo
          }
        } = saga
      ) do
    %{full_name: full_name} =
      rent_application_id
      |> rent_application_repo.get_aggregate()
      |> RentApplication.lease_holdering_person()

    %{
      saga
      | person_full_name: full_name,
        app_count_struct: "AppCount.RentApply.RentApplication",
        app_count_id: rent_application_id
    }
  end

  # this sets up for the monthy rent payment
  # skip since without a rent_payment_id, this must be a rental application
  def rent_payment(%{rent_payment_id: :not_set} = saga) do
    saga
  end

  # this sets up for the monthy rent payment
  def rent_payment(
        %InvoiceSaga{
          status: :started,
          rent_application_id: :not_set,
          rent_payment_id: payment_id
        } = saga
      ) do
    payment = AppCount.Ledgers.PaymentRepo.get_aggregate(payment_id)

    full_name = AppCount.Tenants.Tenant.full_name(payment.tenant)

    %{
      saga
      | person_full_name: full_name,
        app_count_struct: "AppCount.Ledgers.Payment",
        app_count_id: payment_id
    }
  end

  def validate_after_load(%InvoiceSaga{} = saga) do
    request_params = Map.from_struct(saga)

    changeset = InvoiceSaga.after_load_changeset(request_params)

    if changeset.valid? do
      saga
    else
      add_error(saga, errors_on(changeset))
    end
  end

  def create_customer_for_application(%InvoiceSaga{status: :error} = saga) do
    Logger.warning("skipping create_customer_for_application")
    saga
  end

  def create_customer_for_application(
        %InvoiceSaga{
          status: :started,
          soft_ledger_token: token,
          person_full_name: person_full_name,
          app_count_struct: app_count_struct,
          app_count_id: app_count_id,
          deps: %{
            finance_port: finance_port,
            softledger_repo: softledger_repo
          }
        } = saga
      ) do
    request = CreateCustomerRequest.new(%{name: person_full_name})

    case finance_port.create_customer(request, token) do
      {:ok, %CreateCustomerResponse{_id: underscore_id}} ->
        softledger_repo.insert(%{
          soft_ledger_type: "Customer",
          soft_ledger_underscore_id: underscore_id,
          app_count_struct: app_count_struct,
          app_count_id: app_count_id
        })

        saga = Map.put(saga, :customer_id, underscore_id)
        saga

      {:error, message} ->
        message = "create_customer #{inspect(message)} #{inspect(request)}"
        Logger.error(message)
        add_error(saga, message)
    end
  end

  def add_items(%InvoiceSaga{status: :error} = saga) do
    Logger.warning("skipping add_items")
    saga
  end

  def add_items(%InvoiceSaga{status: :started, line_items: line_items} = saga) do
    %{saga | invoice_line_items: invoice_line_items(line_items)}
  end

  defp invoice_line_items(line_items) do
    Enum.map(line_items, &to_invoice_line_item/1)
  end

  defp to_invoice_line_item(
         %{
           amount_in_cents: amount_in_cents,
           account_id: account_id,
           description: description
         } = _line_item
       ) do
    soft_ledger_account_id = SoftLedgerTranslationRepo.soft_ledger_account_id(account_id)

    %AppCount.Core.Ports.SoftLedgerBehaviour.InvoiceLineItem{
      description: description,
      unitAmount: Money.amount_as_string(amount_in_cents),
      LedgerAccountId: soft_ledger_account_id
    }
  end

  def create_invoice(%InvoiceSaga{status: :error} = saga) do
    Logger.warning("skipping create_invoice")
    saga
  end

  # TODO: so far,  only connected to application create, not lease payments.
  def create_invoice(
        %InvoiceSaga{
          status: :started,
          customer_id: customer_id,
          invoice_line_items: invoice_line_items,
          soft_ledger_token: token,
          deps: %{
            finance_port: finance_port
          }
        } = saga
      ) do
    request =
      %{AgentId: customer_id}
      |> CreateInvoiceRequest.new()
      |> add_invoice_line_items(invoice_line_items)

    case finance_port.create_invoice(request, token) do
      {:ok, %CreateInvoiceResponse{_id: underscore_id} = create_invoice_response} ->
        insert_translation(saga, underscore_id)

        %{
          saga
          | status: :invoice_created,
            create_invoice_response: create_invoice_response,
            invoice_underscore_id: underscore_id
        }

      {:error, message} ->
        message = "create_invoice #{inspect(message)} #{inspect(request)}"
        Logger.error(message)
        add_error(saga, message)
    end
  end

  defp add_invoice_line_items(request, invoice_line_items) do
    Enum.reduce(
      invoice_line_items,
      request,
      fn item, request ->
        CreateInvoiceRequest.add_item(request, item)
      end
    )
  end

  def issue_invoice(%InvoiceSaga{status: :error} = saga) do
    Logger.warning("skipping issue_invoice")
    saga
  end

  def issue_invoice(
        %InvoiceSaga{
          status: :invoice_created,
          invoice_underscore_id: invoice_underscore_id,
          soft_ledger_token: token,
          deps: %{
            finance_port: finance_port
          }
        } = saga
      ) do
    request =
      %{id: invoice_underscore_id}
      |> IssueInvoiceRequest.new()

    case finance_port.issue_invoice(request, token) do
      {:ok, %StatusResponse{status: 200} = issue_invoice_response} ->
        %{
          saga
          | status: :invoice_issued,
            issue_invoice_response: issue_invoice_response
        }

      {:error, message} ->
        message = "issue_invoice #{inspect(message)} #{inspect(request)}"
        Logger.error(message)
        add_error(saga, message)
    end
  end

  defp insert_translation(
         # for rent_application
         %{rent_application_id: rent_application_id, deps: %{softledger_repo: softledger_repo}} =
           _saga,
         underscore_id
       ) do
    softledger_repo.insert(%{
      soft_ledger_type: "Invoice",
      soft_ledger_underscore_id: underscore_id,
      app_count_struct: "AppCount.RentApply.RentApplication",
      app_count_id: rent_application_id
    })
  end

  def create_cash_receipt(%{status: :error} = saga) do
    Logger.warning("skipping create_cash_receipt")
    saga
  end

  def create_cash_receipt(
        %{
          status: :invoice_issued,
          soft_ledger_token: token,
          create_invoice_response: create_invoice_response,
          deps: %{
            finance_port: finance_port
          }
        } = saga
      ) do
    request = cash_receipt_request(create_invoice_response)

    case finance_port.create_cash_receipt(request, token) do
      {:ok, %CreateCashReceiptResponse{} = create_cash_receipt_response} ->
        %{
          saga
          | status: :cash_receipt_created,
            create_cash_receipt_response: create_cash_receipt_response
        }

      {:error, message} ->
        message = "create_cash_receipt #{inspect(message)} #{inspect(request)}"
        Logger.error(message)
        add_error(saga, message)
    end
  end

  def cash_receipt_request(
        %CreateInvoiceResponse{
          AgentId: agent_id,
          ARAccountId: a_r_a_account_id,
          LocationId: location_id
        } = create_invoice_response
      ) do
    invoice = create_invoice_response

    {amount, _remainder_of_binary} = Float.parse(invoice.amount)

    today = AppCount.Core.Clock.today() |> to_string()

    %{
      postingDate: today,
      AgentId: agent_id,
      amount: amount,
      currency: "USD",
      LedgerAccountId: a_r_a_account_id,
      LocationId: location_id,
      receiveDate: today
    }
    |> CreateCashReceiptRequest.new()
  end

  def create_payment_request(
        %CreateInvoiceResponse{
          LocationId: location_id
        } = create_invoice_response,
        %CreateCashReceiptResponse{} = create_cash_receipt_response
      ) do
    invoice = create_invoice_response
    cash_receipt = create_cash_receipt_response

    {amount, _remainder_of_binary} = Float.parse(invoice.amount)

    today = AppCount.Core.Clock.today() |> to_string()

    %{
      paymentDate: today,
      type: "cashreceipt",
      amount: amount,
      currency: "USD",
      LocationId: location_id,
      InvoiceId: invoice._id,
      CashReceiptId: cash_receipt._id
    }
    |> CreatePaymentRequest.new()
  end

  def create_payment(%{status: :error} = saga) do
    Logger.warning("skipping create_payment")
    saga
  end

  def create_payment(
        %{
          status: :cash_receipt_created,
          soft_ledger_token: token,
          create_invoice_response: create_invoice_response,
          create_cash_receipt_response: create_cash_receipt_response,
          deps: %{
            finance_port: finance_port
          }
        } = saga
      ) do
    create_payment_request =
      create_payment_request(create_invoice_response, create_cash_receipt_response)

    case finance_port.create_payment(create_payment_request, token) do
      {:ok, %CreatePaymentResponse{} = create_payment_response} ->
        %{
          saga
          | status: :payment_created,
            create_payment_response: create_payment_response
        }

      {:error, message} ->
        message = "create_payment #{inspect(message)} #{inspect(create_payment_request)}"
        Logger.error(message)
        add_error(saga, message)
    end
  end

  def log_errors(%InvoiceSaga{status: :error} = saga) do
    saga = %{saga | soft_ledger_token: "soft_ledger_token removed for printing"}
    Logger.error(inspect(saga, limit: :infinity))
    saga
  end

  def log_errors(%InvoiceSaga{} = saga) do
    saga
  end

  def publish_result(
        %{
          status: status,
          app_count_struct: app_count_struct,
          app_count_id: app_count_id,
          error_message: error_message
        } = saga
      ) do
    InvoiceSagaTopic.completed(
      {app_count_struct, app_count_id},
      %{status: status, error_message: error_message},
      __MODULE__
    )

    saga
  end

  # ---------------- Private -------------------

  def add_error(%{error_message: ""} = saga, message) do
    %{saga | status: :error, error_message: "#{message}"}
  end

  def add_error(%{error_message: old_message} = saga, message) do
    %{saga | status: :error, error_message: "#{old_message}; #{message}"}
  end

  defp errors_on(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map_join(", ", fn {key, val} -> ~s{#{key}: "#{val}"} end)
  end
end
