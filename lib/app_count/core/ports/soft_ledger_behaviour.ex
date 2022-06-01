defmodule AppCount.Core.Ports.SoftLedgerBehaviour do
  alias AppCount.Core.Ports.RequestSpec
  alias AppCount.Core.Ports.RequestBehaviour
  alias AppCount.Core.Ports.ResponseBehaviour
  alias AppCount.Core.Clock

  @moduledoc """
  (1) defines the Request/Response structs for the interface to SoftLedger
  (2) defines the functions needed by the adapter and the fake
  (3) provides a way to alias all the types in this interface module

  Some API calls (for example "delete") do not need a response struct, so they use a regular Map for the non-response.
  """

  defmodule OAuthResponse do
    @moduledoc """
    https://api.softledger.com/docs#section/OAuth-v2.0
    """
    @behaviour ResponseBehaviour
    defstruct expires_in: 0,
              access_token: "Not Set"

    @impl ResponseBehaviour
    def new(jbody) when is_map(jbody) do
      struct(__MODULE__, jbody)
    end
  end

  defmodule StatusResponse do
    @behaviour ResponseBehaviour
    defstruct status: 0

    @impl ResponseBehaviour
    def new(attrs) when is_map(attrs) do
      struct(__MODULE__, attrs)
    end
  end

  defmodule NoResponse do
    @behaviour ResponseBehaviour
    defstruct unused: nil

    @impl ResponseBehaviour
    def new(_attrs \\ nil) do
      %__MODULE__{}
    end
  end

  #
  # =================================================================== Journal
  #

  defmodule CreateJournalRequest do
    @moduledoc """
    https://api.softledger.com/docs#tag/Journal/paths/~1journals/post
    """
    @behaviour RequestBehaviour

    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field(:status, :string)
      field(:entryType, :string)
      field(:sourceLedger, :string)
      field(:reference, :string)
      field(:currency, :string, default: "USD")

      has_many(
        :transactions,
        AppCount.Core.Ports.SoftLedgerBehaviour.CreateJournalTransactionRequest
      )
    end

    @impl RequestBehaviour
    def returning, do: AppCount.Core.Ports.SoftLedgerBehaviour.CreateJournalResponse

    @impl RequestBehaviour
    def path(base, _id \\ nil), do: "#{base}/journals"

    @impl RequestBehaviour
    def verb, do: :post

    @impl RequestBehaviour
    def new(attrs) when is_map(attrs) do
      struct(__MODULE__, attrs)
    end

    def changeset(%__MODULE__{} = request, params \\ %{}) do
      request
      |> cast(
        params,
        [
          :status,
          :entryType,
          :sourceLedger,
          :reference
          # :transactions
        ]
      )
      |> validate_required([
        :status,
        :entryType,
        :sourceLedger,
        :reference
        # WIP :transactions
      ])
      |> validate_inclusion(:status, ["draft", "posted"], message: ~s[must be "draft" or "posted"])
      |> validate_inclusion(:entryType, ["Standard", "Reversing"],
        message: ~s[must be "Standard" or "Reversing"]
      )
      |> validate_inclusion(:sourceLedger, ["Financial", "AR", "AP"],
        message: ~s[must be "Financial", "AR", or "AP"]
      )
    end
  end

  defmodule CreateJournalTransactionRequest do
    use Ecto.Schema
    import Ecto.Changeset

    # WIP
    @root_location_id AppCount.Adapters.SoftLedger.Config.load().parent_id

    embedded_schema do
      # Cannot be in the future. Should be the same for all lines
      field(:transactionDate, :string)
      # Should be the same for all lines
      field(:postedDate, :string)
      # Must be >= 0. Must be 0 if credit is > 0.
      field(:debit, :string)
      # Must be >= 0. Must be 0 if debit is > 0.
      field(:credit, :string)
      field(:LocationId, :integer, default: @root_location_id)
      field(:LedgerAccountId, :integer)
    end

    def changeset(%__MODULE__{} = request, params \\ %{}) do
      request
      |> cast(
        params,
        [
          :transactionDate,
          :postedDate,
          :debit,
          :credit,
          :LedgerAccountId
        ]
      )
      |> validate_required([
        :transactionDate,
        :postedDate,
        :debit,
        :credit,
        :LedgerAccountId
      ])
      |> validate_credit_and_debit()
      |> validate_not_future_date(:transactionDate)
    end

    def validate_not_future_date(changeset, key) when is_atom(key) do
      future =
        changeset.changes
        |> Map.get(key)
        |> case do
          nil -> nil
          future -> Clock.date_from_iso8601!(future) |> Clock.greater_than(Clock.today())
        end

      if future do
        add_error(changeset, key, ~s[Cannot be in the future])
      else
        changeset
      end
    end

    def validate_credit_and_debit(%{changes: %{credit: "0", debit: "0"}} = changeset) do
      changeset
      |> add_error(:credit, ~s["credit" and "debit" may not both be zero])
      |> add_error(:debit, ~s["credit" and "debit" may not both be zero])
    end

    def validate_credit_and_debit(changeset) do
      changeset
    end
  end

  defmodule CreateJournalResponse do
    @behaviour ResponseBehaviour

    defstruct _id: :not_set,
              number: :not_set,
              status: :not_set,
              entryType: :not_set,
              sourceLedger: :not_set,
              reference: :not_set,
              notes: :not_set,
              attachments: [],
              reverseDate: :not_set,
              icDoc: :not_set,
              createdAt: :not_set,
              updatedAt: :not_set,
              AccountingPeriodId: :not_set,
              transactions: []

    defmodule Transaction do
      defstruct _id: :not_set,
                description: :not_set,
                debit: :not_set,
                credit: :not_set,
                transactionDate: :not_set,
                postedDate: :not_set,
                reconcileId: :not_set,
                currency: :not_set,
                consolidated: :not_set,
                reversing: :not_set,
                elimination: :not_set,
                elim2: :not_set,
                SystemJobId: :not_set,
                CostCenterId: :not_set,
                LedgerAccountId: :not_set,
                JobId: :not_set,
                ProductId: :not_set,
                LocationId: :not_set,
                InvoiceId: :not_set,
                BillId: :not_set,
                AgentId: :not_set,
                Vendorid: :not_set,
                ICLocationId: :not_set,
                CashReceiptId: :not_set,
                VendorCreditId: :not_set,
                ICAccountId: :not_set,
                PaymentId: :not_set,
                ForexRateId: :not_set,
                ProductionId: :not_set,
                JournalId: :not_set
    end

    @impl ResponseBehaviour
    def new(jbody) when is_map(jbody) do
      struct(__MODULE__, jbody)
      |> load_transaction()
    end

    defp load_transaction(%{transactions: transactions} = response) when is_list(transactions) do
      alias AppCount.Core.Ports.SoftLedgerBehaviour.CreateJournalResponse.Transaction

      transactions =
        transactions
        |> Enum.map(fn entry_params -> struct(Transaction, entry_params) end)

      %{response | transactions: transactions}
    end
  end

  # This is INDEX but SoftLedger calls it "get"  because thats what they do.
  defmodule GetJournalRequest do
    @moduledoc """
    https://api.softledger.com/docs#tag/Journal/paths/~1journals/get
    """
    @behaviour RequestBehaviour

    defstruct filter: :not_set

    @impl RequestBehaviour
    def returning, do: AppCount.Core.Ports.SoftLedgerBehaviour.GetJournalResponse

    @impl RequestBehaviour
    def path(base, _id \\ nil), do: "#{base}/journals"

    @impl RequestBehaviour
    def verb, do: :get

    @impl RequestBehaviour
    def new(attrs) when is_map(attrs) do
      struct(__MODULE__, attrs)
    end
  end

  defmodule GetJournalResponse do
    @moduledoc """
    https://api.softledger.com/docs#tag/Journal/paths/~1journals/get
    """
    @behaviour ResponseBehaviour

    defmodule Data do
      defstruct _id: :not_set,
                amount: :not_set,
                SystemJobId: :not_set,
                currency: :not_set,
                postedDate: :not_set,
                transactionDate: :not_set,
                number: :not_set,
                # enum: "Financial" "AR" "AP"
                sourceLedger: :not_set,
                # enum:  "draft" "posted"
                status: :not_set,
                # enum: "Standard" "Reversing"
                entryType: :not_set,
                reverseDate: :not_set,
                reference: :not_set,
                createdAt: :not_set,
                updatedAt: :not_set,
                attachments: [],
                Location: :not_set
    end

    defstruct totalItems: 0, data: []

    def new(jbody) when is_map(jbody) do
      struct(__MODULE__, jbody)
      |> load_data()
    end

    defp load_data(%{data: data} = response) when is_list(data) do
      alias AppCount.Core.Ports.SoftLedgerBehaviour.GetJournalResponse.Data

      data =
        data
        |> Enum.map(fn entry_params -> struct(Data, entry_params) end)

      %{response | data: data}
    end
  end

  defmodule DeleteJournalRequest do
    @moduledoc """
    https://api.softledger.com/docs#tag/Journal/paths/~1journals~1{_id}/delete
    """
    @behaviour RequestBehaviour
    defstruct id: :not_set

    @impl RequestBehaviour
    def returning, do: AppCount.Core.Ports.SoftLedgerBehaviour.StatusResponse

    @impl RequestBehaviour
    def path(base, id), do: "#{base}/journals/#{id}"

    @impl RequestBehaviour
    def verb, do: :delete

    @impl RequestBehaviour
    def new(jbody) when is_map(jbody) do
      struct(__MODULE__, jbody)
    end
  end

  #
  # =================================================================== PAYMENT
  #

  defmodule CreatePaymentRequest do
    @moduledoc """
    https://api.softledger.com/docs#tag/Payment/paths/~1payments/post
    """
    @behaviour RequestBehaviour

    # type: "manual" "check" "vendorcredit" "cashreceipt" "refund" "ap_refund"
    defstruct type: "manual",
              paymentDate: "2000-01-01",
              # Must be > 0 for types 'manual', 'check', 'vendorcredit', 'cashreceipt'
              # Must be < 0 for types 'refund', 'ap_refund'
              amount: "0.00",
              LocationId: 0,
              currency: "USD",
              # externalId: "externalId",
              # externalCheckId string
              # externalCheckBankId string:  Required if type is 'check'
              # number string
              # checkNumber string
              # postedDate string <date> Default: "Uses paymentDate"
              # memo string
              # notes string
              # attachments Array of strings <URI>
              # BillId integer  Ref: Bill._id
              # Required and Bill.amount > 0 if type is 'manual', 'check', 'vendorcredit'
              # Required and Bill.amount < 0 if type is 'ap_refund'
              # VendorCreditId integer
              # LedgerAccountId integer
              CashReceiptId: 0,
              # AddressId integer
              # Ref: Invoice._id
              # Required and Invoice.amount > 0 if type is 'cashreceipt'
              # Required and Invoice.amount < 0 if type is 'refund'
              InvoiceId: 0

    @impl RequestBehaviour
    def returning, do: AppCount.Core.Ports.SoftLedgerBehaviour.CreatePaymentResponse

    @impl RequestBehaviour
    def path(base, _id \\ nil), do: "#{base}/payments"

    @impl RequestBehaviour
    def verb, do: :post

    @impl RequestBehaviour
    def new(attrs) when is_map(attrs) do
      today = AppCount.Core.Clock.today() |> to_string()

      struct(__MODULE__, attrs)
      |> Map.put(:paymentDate, today)
    end
  end

  defmodule CreatePaymentResponse do
    @moduledoc """
    https://api.softledger.com/docs#tag/Payment/paths/~1payments/post
    """
    @behaviour ResponseBehaviour

    defstruct _id: 0,
              externalId: "string",
              externalCheckId: "string",
              externalCheckBankId: "string",
              # type: "manual" "check" "vendorcredit" "cashreceipt" "refund" "ap_refund"
              type: "manual",
              number: "string",
              checkNumber: "string",
              #  "created" "approved" "voided"
              status: "created",
              amount: "1.00",
              paymentDate: "2000-01-01",
              postedDate: "2000-01-01",
              memo: "string",
              notes: "string",
              attachments: [],
              currency: "USD",
              BillId: 0,
              VendorCreditId: 0,
              LedgerAccountId: 0,
              CashReceiptId: 0,
              AddressId: 0,
              LocationId: 0,
              InvoiceId: 0

    @impl ResponseBehaviour
    def new(jbody) when is_map(jbody) do
      struct(__MODULE__, jbody)
    end
  end

  #
  # =================================================================== CASH RECEIPT
  #

  defmodule CreateCashReceiptRequest do
    @moduledoc """
    https://api.softledger.com/docs#tag/Cash-Receipt/paths/~1cashReceipts/post
    """
    @behaviour RequestBehaviour

    defstruct postingDate: "2000-01-01",
              #  Customer._id
              AgentId: 0,
              amount: 0.00,
              currency: "USD",
              # Ref: LedgerAccount._id
              LedgerAccountId: 231,
              # Ref: Location._id
              LocationId: 123,
              receiveDate: "2000-01-01"

    @impl RequestBehaviour
    def returning, do: AppCount.Core.Ports.SoftLedgerBehaviour.CreateCashReceiptResponse

    @impl RequestBehaviour
    def path(base, _id \\ nil), do: "#{base}/cashReceipts"

    @impl RequestBehaviour
    def verb, do: :post

    @impl RequestBehaviour
    def new(attrs) when is_map(attrs) do
      struct(__MODULE__, attrs)
    end
  end

  defmodule CreateCashReceiptResponse do
    @moduledoc """
    https://api.softledger.com/docs#tag/Cash-Receipt/paths/~1cashReceipts/post
    """
    @behaviour ResponseBehaviour

    defstruct _id: 0,
              number: "string",
              # Type:  "charge" "check" "ACH" "Wire"
              type: "string",
              amount: 0.00,
              unused: 0,
              description: "not_set",
              attachments: [],
              currency: "USD",
              receiveDate: "2000-01-01",
              postingDate: "2000-01-01",
              # status: "created" "voided" "partiallyApplied" "applied"
              status: "created",
              applyToInvoices: true,
              externalId: "string",
              AgentId: 0,
              LedgerAccountId: 0,
              LocationId: 0,
              # TODO: create this account?
              # We probably do not need it at this moment --EM
              UnappliedCashAccountId: 0

    @impl ResponseBehaviour
    def new(jbody) when is_map(jbody) do
      struct(__MODULE__, jbody)
    end
  end

  #
  # =================================================================== INVOICE
  #

  defmodule InvoiceLineItem do
    defstruct description: "not_set",
              unitAmount: "1.00",
              quantity: "1",
              LedgerAccountId: 0
  end

  defmodule IssueInvoiceRequest do
    @moduledoc """
    https://api.softledger.com/docs#tag/Invoice/paths/~1invoices~1{_id}~1issue/put
    """

    @behaviour RequestBehaviour
    defstruct id: :not_set

    @impl RequestBehaviour
    def returning, do: :no_return_data

    @impl RequestBehaviour
    def path(base, id), do: "#{base}/invoices/#{id}/issue"

    @impl RequestBehaviour
    def verb, do: :put

    @impl RequestBehaviour
    def new(attrs) when is_map(attrs) do
      struct(__MODULE__, attrs)
    end
  end

  defmodule CreateInvoiceRequest do
    @moduledoc """
    https://api.softledger.com/docs#tag/Invoice/paths/~1invoices/post
    """
    @behaviour RequestBehaviour
    @root_location_id AppCount.Adapters.SoftLedger.Config.load().parent_id
    @ar_account_id AppCount.Adapters.SoftLedger.Config.load().ar_account_id

    defstruct AgentId: :not_set,
              ARAccountId: @ar_account_id,
              LocationId: @root_location_id,
              currency: "USD",
              InvoiceLineItems: []

    @impl RequestBehaviour
    def returning,
      do: AppCount.Core.Ports.SoftLedgerBehaviour.CreateInvoiceResponse

    @impl RequestBehaviour
    def path(base, _id \\ nil), do: "#{base}/invoices"

    @impl RequestBehaviour
    def verb, do: :post

    @impl RequestBehaviour
    def new(attrs) when is_map(attrs) do
      struct(__MODULE__, attrs)
    end

    def add_item(%__MODULE__{InvoiceLineItems: invoice_line_items} = request, %{
          description: description,
          unitAmount: unit_amount_sting,
          LedgerAccountId: account_id
        }) do
      line_item =
        %AppCount.Core.Ports.SoftLedgerBehaviour.InvoiceLineItem{
          description: description,
          unitAmount: unit_amount_sting,
          LedgerAccountId: account_id
        }
        |> Map.from_struct()

      mod_invoice_line_items = [line_item | invoice_line_items]

      %{request | InvoiceLineItems: mod_invoice_line_items}
    end
  end

  defmodule CreateInvoiceResponse do
    @moduledoc """
    https://api.softledger.com/docs#tag/Invoice/paths/~1invoices/post
    """
    @behaviour ResponseBehaviour
    defstruct _id: 0,
              externalId: "string",
              type: "string",
              number: "string",
              # status: "created" "issued" "partialPayment" "paid" "voided"
              status: "created",
              amount: "0.00",
              amountPayable: "0.00",
              url: "string",
              invoiceDate: "2000-01-01",
              postedDate: "2000-01-01",
              dueDate: "2000-01-01",
              notes: "string",
              attachments: [],
              reference: "string",
              currency: "USD",
              SystemJobId: "string",
              LocationId: 0,
              ICLocationId: 0,
              AgentId: 0,
              ShippingAddressId: 0,
              BillingAddressId: 0,
              ARAccountId: 0,
              TemplateId: 0,
              SalesOrderId: 0,
              InvoiceLineItems: []

    @impl ResponseBehaviour
    def new(jbody) when is_map(jbody) do
      struct(__MODULE__, jbody)
    end
  end

  #
  # =================================================================== LOCATION
  #
  defmodule CreateLocationRequest do
    @moduledoc """
    https://api.softledger.com/docs#tag/Location/paths/~1locations/post
    """
    @behaviour RequestBehaviour
    @root_location_id AppCount.Adapters.SoftLedger.Config.load().parent_id

    defstruct id: :not_set,
              parent_id: @root_location_id,
              name: :not_set,
              currency: "USD"

    @impl RequestBehaviour
    def returning, do: AppCount.Core.Ports.SoftLedgerBehaviour.CreateLocationResponse

    @impl RequestBehaviour
    def path(base, _id \\ nil), do: "#{base}/locations"

    @impl RequestBehaviour
    def verb, do: :post

    @impl RequestBehaviour
    def new(attrs) when is_map(attrs) do
      struct(__MODULE__, attrs)
    end
  end

  defmodule CreateLocationResponse do
    @moduledoc """
    https://api.softledger.com/docs#tag/Location/paths/~1locations/post
    """
    @behaviour ResponseBehaviour

    defstruct _id: 0,
              id: "0",
              name: "not_set",
              currency: "USD",
              description: "",
              parent_id: 0,
              parent_path: [0],
              imageURL: "",
              entityname: "",
              entityEmail: "",
              entityPhone: "",
              entityEIN: "",
              paymentDetails: "",
              AddressId: 0,
              FXGLAccountId: 0,
              RAAccountId: 0

    @impl ResponseBehaviour
    def new(jbody) when is_map(jbody) do
      struct(__MODULE__, jbody)
    end
  end

  defmodule DeleteLocationRequest do
    @moduledoc """
    https://api.softledger.com/docs#tag/Location/paths/~1locations~1{_id}/delete
    """
    @behaviour RequestBehaviour
    defstruct id: :not_set

    @impl RequestBehaviour
    def returning, do: AppCount.Core.Ports.SoftLedgerBehaviour.StatusResponse

    @impl RequestBehaviour
    def path(base, id), do: "#{base}/locations/#{id}"

    @impl RequestBehaviour
    def verb, do: :delete

    @impl RequestBehaviour
    def new(jbody) when is_map(jbody) do
      struct(__MODULE__, jbody)
    end
  end

  #
  # =================================================================== Account
  #
  defmodule CreateUpdateAccountRequest do
    @moduledoc """
    https://api.softledger.com/docs#tag/Ledger-Account/paths/~1ledger_accounts/post
    """
    @behaviour RequestBehaviour

    use Ecto.Schema
    import Ecto.Changeset
    @root_location_id AppCount.Adapters.SoftLedger.Config.load().parent_id

    embedded_schema do
      field(:name, :string)
      field(:number, :string)
      field(:naturalBalance, :string)
      field(:type, :string)
      field(:subtype, :string)
      field(:LocationId, :integer, default: @root_location_id)
      field(:description, :string)
    end

    def changeset(%__MODULE__{} = request, params \\ %{}) do
      request
      |> cast(
        params,
        [
          :name,
          :number,
          :naturalBalance,
          :type,
          :subtype,
          :description
        ]
      )
      |> validate_required([
        :name,
        :number,
        :naturalBalance,
        :type,
        :subtype
      ])
      |> validate_inclusion(:naturalBalance, ["credit", "debit"],
        message: ~s[must be "credit" or "debit"]
      )
      |> validate_inclusion(:type, ["Asset", "Liability", "Equity", "Revenue", "Expense"],
        message: ~s[must be "Asset", "Liability", "Equity", "Revenue", or "Expense"]
      )
      |> validate_length(:subtype, min: 2, max: 255)
      |> validate_length(:number, is: 8)
      |> validate_number(:LocationId,
        equal_to: @root_location_id,
        message: "must be equal to #{@root_location_id}"
      )
    end

    @impl RequestBehaviour
    def returning, do: AppCount.Core.Ports.SoftLedgerBehaviour.CreateUpdateAccountResponse

    @impl RequestBehaviour
    def path(base, _id \\ nil), do: "#{base}/ledger_accounts"

    @impl RequestBehaviour
    def verb, do: :post

    @impl RequestBehaviour
    def new(attrs) when is_map(attrs) do
      struct(__MODULE__, attrs)
    end
  end

  defmodule CreateUpdateAccountResponse do
    @behaviour ResponseBehaviour
    defstruct _id: 0,
              name: "not_set",
              number: "00000000",
              qbSubType: "deprecated",
              naturalBalance: :not_set,
              type: :not_set,
              subtype: "not_set",
              description: "not_set",
              includeLocationChildren: :not_set,
              canDelete: :not_set,
              revalue_fx: :not_set,
              inactive: :not_set,
              LocationId: 0,
              ICAccountId: 0

    @impl ResponseBehaviour
    def new(jbody) when is_map(jbody) do
      struct(__MODULE__, jbody)
    end
  end

  defmodule DeleteAccountRequest do
    @moduledoc """
    https://api.softledger.com/docs#tag/Ledger-Account/paths/~1ledger_accounts~1{_id}/delete
    """
    @behaviour RequestBehaviour

    defstruct id: :not_set

    @impl RequestBehaviour
    def returning, do: AppCount.Core.Ports.SoftLedgerBehaviour.StatusResponse

    @impl RequestBehaviour
    def verb, do: :delete

    @impl RequestBehaviour
    def path(base, id), do: "#{base}/ledger_accounts/#{id}"

    @impl RequestBehaviour
    def new(jbody) when is_map(jbody) do
      struct(__MODULE__, jbody)
    end
  end

  #
  # =================================================================== Customer
  #

  defmodule CreateCustomerRequest do
    @moduledoc """
    https://api.softledger.com/docs#tag/Customer/paths/~1customers/post
    """
    @behaviour RequestBehaviour

    defstruct name: :not_set

    @impl RequestBehaviour
    def returning, do: AppCount.Core.Ports.SoftLedgerBehaviour.CreateCustomerResponse

    @impl RequestBehaviour
    def path(base, _id \\ nil), do: "#{base}/customers"

    @impl RequestBehaviour
    def verb, do: :post

    @impl RequestBehaviour
    def new(attrs) when is_map(attrs) do
      struct(__MODULE__, attrs)
    end
  end

  defmodule DeleteCustomerRequest do
    @moduledoc """
    https://api.softledger.com/docs#tag/Customer/paths/~1customers~1{_id}/delete
    """
    @behaviour RequestBehaviour
    defstruct id: :not_set

    @impl RequestBehaviour
    def returning, do: AppCount.Core.Ports.SoftLedgerBehaviour.StatusResponse

    @impl RequestBehaviour
    def verb, do: :delete

    @impl RequestBehaviour
    def path(base, id), do: "#{base}/customers/#{id}"

    @impl RequestBehaviour
    def new(attrs) when is_map(attrs) do
      struct(__MODULE__, attrs)
    end
  end

  defmodule CreateCustomerResponse do
    @behaviour ResponseBehaviour

    defstruct _id: 0,
              id: "not_set",
              externalId: "not_set",
              name: "not_set",
              email: "not_set",
              type: "not_set",
              description: "not_set",
              website: "not_set",
              terms: "not_set",
              notes: "not_set",
              customFields: "not_set",
              attachments: "not_set"

    @impl ResponseBehaviour
    def new(jbody) when is_map(jbody) do
      struct(__MODULE__, jbody)
    end
  end

  # --------------- CALLBACKS ---------------------------------------------------------
  @type service_safe_call_fn :: (RequestSpec.t() -> any())
  @type ok_error_response :: {:ok, Response.t()} | {:error, String.t()}

  @callback request_spec(list()) :: RequestSpec.t()

  @callback fetch_token(function()) :: {:ok, OAuthResponse.t()} | {:error, String.t()}

  # Cash Receipt
  @callback create_cash_receipt(RequestSpec.t(), service_safe_call_fn) ::
              ok_error_response

  # Invoice
  @callback create_invoice(RequestSpec.t(), service_safe_call_fn) ::
              ok_error_response

  @callback issue_invoice(RequestSpec.t(), service_safe_call_fn) ::
              ok_error_response

  # Customer
  @callback create_customer(RequestSpec.t(), service_safe_call_fn) ::
              ok_error_response

  @callback delete_customer(RequestSpec.t(), service_safe_call_fn) ::
              :ok

  # Location

  @callback create_location(RequestSpec.t(), service_safe_call_fn) ::
              {:ok, RequestSpec.t()} | {:error, String.t()}

  @callback delete_location(RequestSpec.t(), service_safe_call_fn) ::
              :ok

  # Account
  @callback create_account(RequestSpec.t(), service_safe_call_fn) ::
              ok_error_response

  @callback update_account(RequestSpec.t(), service_safe_call_fn) ::
              ok_error_response

  @callback delete_account(RequestSpec.t(), service_safe_call_fn) ::
              :ok

  # Payment
  @callback create_payment(RequestSpec.t(), service_safe_call_fn) ::
              ok_error_response

  # Journals
  @callback create_journal(RequestSpec.t(), service_safe_call_fn) ::
              ok_error_response

  @callback get_journal(RequestSpec.t(), service_safe_call_fn) ::
              ok_error_response

  @callback delete_journal(RequestSpec.t(), service_safe_call_fn) ::
              ok_error_response

  def alias_requests_and_responses do
    quote do
      alias AppCount.Core.Ports.SoftLedgerBehaviour

      # Status
      alias AppCount.Core.Ports.SoftLedgerBehaviour.StatusResponse

      # OAuth
      alias AppCount.Core.Ports.SoftLedgerBehaviour.OAuthResponse

      # Cash Receipt
      alias AppCount.Core.Ports.SoftLedgerBehaviour.CreateCashReceiptRequest
      alias AppCount.Core.Ports.SoftLedgerBehaviour.CreateCashReceiptResponse

      # Invoice
      alias AppCount.Core.Ports.SoftLedgerBehaviour.CreateInvoiceRequest
      alias AppCount.Core.Ports.SoftLedgerBehaviour.CreateInvoiceResponse
      alias AppCount.Core.Ports.SoftLedgerBehaviour.InvoiceLineItem
      alias AppCount.Core.Ports.SoftLedgerBehaviour.IssueInvoiceRequest

      # Location
      alias AppCount.Core.Ports.SoftLedgerBehaviour.CreateLocationRequest
      alias AppCount.Core.Ports.SoftLedgerBehaviour.CreateLocationResponse
      alias AppCount.Core.Ports.SoftLedgerBehaviour.DeleteLocationRequest

      # Account
      alias AppCount.Core.Ports.SoftLedgerBehaviour.CreateUpdateAccountRequest
      alias AppCount.Core.Ports.SoftLedgerBehaviour.CreateUpdateAccountResponse
      alias AppCount.Core.Ports.SoftLedgerBehaviour.DeleteAccountRequest

      # Customer
      alias AppCount.Core.Ports.SoftLedgerBehaviour.CreateCustomerRequest
      alias AppCount.Core.Ports.SoftLedgerBehaviour.CreateCustomerResponse
      alias AppCount.Core.Ports.SoftLedgerBehaviour.DeleteCustomerRequest

      # Payment
      alias AppCount.Core.Ports.SoftLedgerBehaviour.CreatePaymentRequest
      alias AppCount.Core.Ports.SoftLedgerBehaviour.CreatePaymentResponse

      # Journal
      alias AppCount.Core.Ports.SoftLedgerBehaviour.GetJournalRequest
      alias AppCount.Core.Ports.SoftLedgerBehaviour.GetJournalResponse
      alias AppCount.Core.Ports.SoftLedgerBehaviour.CreateJournalRequest
      alias AppCount.Core.Ports.SoftLedgerBehaviour.CreateJournalTransactionRequest
      alias AppCount.Core.Ports.SoftLedgerBehaviour.CreateJournalResponse
      alias AppCount.Core.Ports.SoftLedgerBehaviour.DeleteJournalRequest
    end
  end

  defmacro __using__(which) when which in [:alias_requests_and_responses] do
    apply(__MODULE__, which, [])
  end
end
