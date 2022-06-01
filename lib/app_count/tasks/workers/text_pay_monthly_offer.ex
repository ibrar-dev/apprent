defmodule AppCount.Tasks.Workers.TextPayMonthlyOffer do
  use AppCount.Tasks.Worker, "Monthly TextPay Offer"
  alias AppCount.Messaging.Utils.TextMessageSenders
  alias AppCount.Messaging.Utils.TextMessageTemplates
  alias AppCount.Messaging.PhoneNumberRepo
  alias AppCount.Admins
  alias AppCount.Properties.PropertyRepo
  alias AppCount.Tenants.TenantRepo
  alias AppCount.Accounts.Utils.AccountInfo

  @impl AppCount.Tasks.Worker
  def perform() do
    # Get All properties
    all_properties()
    |> Enum.each(&perform(&1))
  end

  def perform(property_id) do
    today = AppCount.current_date()
    property_name = PropertyRepo.get(property_id).name

    property_phone =
      case PhoneNumberRepo.get_number(property_id, "payments") do
        nil -> nil
        phone -> phone.number
      end

    # Get all tenants for property
    property_id
    # Tenants for the property
    |> TenantRepo.tenants_for_property(today)
    # Get required data per tenant
    |> Enum.map(&TenantRepo.get_aggregate(&1.id))
    # Filter with initial data
    |> perform_filters()
    # Filter after getting balance
    |> get_and_filter_balance()
    # Message remaining tenants
    |> Enum.each(&compile_and_send(&1, property_name, property_phone))
  end

  ## tenant has account
  ## account has sms_accepted
  ## tenant has payment_status of approved
  ## account has active payment_sources
  def perform_filters(tenants) do
    tenants
    |> Enum.filter(
      &(not is_nil(&1.account) and &1.payment_status == "approved" and &1.account.allow_sms)
    )
    |> Enum.filter(&active_payment_sources(&1.account.payment_sources))
  end

  ## account has active payment_sources
  ## Get balance for account
  ## Filter out tenants with balance
  def get_and_filter_balance(tenants) do
    tenants
    |> Enum.map(&Map.merge(&1, %{balance: AccountInfo.user_balance_total(&1.id)}))
    |> Enum.filter(&(Decimal.cmp(&1.balance, 0) == :gt))
  end

  def get_payment_source(account) do
    account.payment_sources
    |> Enum.filter(& &1.active)
    |> Enum.sort_by(& &1.inserted_at, {:desc, NaiveDateTime})
    |> List.first()
    |> case do
      nil -> {:error, "Missing Payment Source"}
      ps -> {:ok, ps}
    end
  end

  def compile_and_send(
        %{phone: phone, balance: balance, account: account, first_name: first_name},
        property_name,
        property_phone
      ) do
    with {:ok, ps} <- get_payment_source(account) do
      offer_to_pay_params = %{
        first_name: first_name,
        property_name: property_name,
        balance: balance,
        last_4: ps.last_4
      }

      %{
        phone: phone,
        from: property_phone,
        text_body:
          TextMessageTemplates.offer_to_pay(offer_to_pay_params, account.preferred_language),
        module: __MODULE__
      }
      |> TextMessageSenders.offer_to_pay()
    else
      error_tuple ->
        error_tuple
    end
  end

  defp active_payment_sources([]), do: false

  defp active_payment_sources(payment_sources) do
    ps =
      payment_sources
      |> Enum.filter(& &1.active)

    length(ps) >= 1
  end

  # To get all the property_ids
  # We should really set up this to be more accessible
  defp fake_admin() do
    %{
      id: "",
      roles: %MapSet{
        map: %{
          "Super Admin" => ""
        }
      }
    }
  end

  def all_properties() do
    fake_admin()
    |> Admins.property_ids_for()
  end
end
