defmodule AppCount.Messaging.Utils.TextMessageReplies do
  @moduledoc """
  All the logic for handling replies from residents should go here.

  As the functionality undoubtedly expands we may need to branch out into different modules.
  Maybe one for payments, one for maintenance etc. But for now this will handle all.

  Hi {First Name}, this is an automated payment text from {Property Name}. The amount due on your account is ${balance}. Simply reply with Y or Yes to pay the balance using your saved payment method in AppRent ending in {last 4 of primary}.

  Hola (first name), este es un pago automático via texto desde {property name}. El balance de su cuenta es ${balance}. Simplemente responda con S o Si para pagar el balance usando el método salvado por defecto en AppRent que termina en {last 4 of primary}.
  """

  alias AppCount.Tenants.TenantRepo
  alias AppCount.Messaging.TextMessageRepo
  alias AppCount.Messaging.Utils.TextMessageTemplates
  alias AppCount.Core.SmsTopic
  alias AppCount.Accounts.Utils.AccountInfo
  alias AppCount.Core.PaymentBoundary
  require Logger

  def handle_message(%{body: "P"} = params), do: pay_message(params)
  def handle_message(%{body: "Pay"} = params), do: pay_message(params)
  def handle_message(%{body: "p"} = params), do: pay_message(params)
  def handle_message(%{body: "pay"} = params), do: pay_message(params)
  def handle_message(%{body: "pagar"} = params), do: pay_message(params)
  def handle_message(%{body: "Pagar"} = params), do: pay_message(params)
  def handle_message(params), do: unrecognized_reply(params)

  def pay_message(%{from_number: from_num} = params) do
    with {:ok, tenant_list} <- get_tenant(from_num),
         {:ok, tenants_with_ps} <- get_tenant_payment(tenant_list),
         {:ok, tenant} <- get_tenant_from_list(tenants_with_ps),
         {:ok, tenant_with_balance} <- gather_balance_data(tenant, params),
         {:ok, _rent_saga} <- process_payment(tenant_with_balance, params) do
      send_successful_payment(tenant, params)
    else
      error ->
        handle_error(error, params)
    end
  end

  # --  Helpers -----------
  def get_language(from_num) when is_binary(from_num) do
    with {:ok, tenant_list} <- get_tenant(from_num),
         {:ok, tenant} <- get_tenant_from_list(tenant_list),
         {:ok, language} <- get_language(tenant) do
      {:ok, language}
    else
      _ ->
        {:ok, nil}
    end
  end

  def get_language(:multiple_tenants), do: {:ok, nil}

  def get_language(tenant) do
    cond do
      tenant.account -> {:ok, tenant.account.preferred_language}
      true -> {:ok, nil}
    end
  end

  def get_tenant(number) do
    tenant_list =
      number
      |> TextMessageRepo.format_number(:no_country_code)
      |> TenantRepo.tenant_by_phone_num()

    {:ok, tenant_list}
  end

  defp get_tenant_payment([]), do: {:error, :no_payment_sources}

  defp get_tenant_payment(list) do
    filtered =
      list
      |> Enum.filter(&(not is_nil(&1.account) and &1.payment_status == "approved"))
      |> Enum.filter(&active_payment_sources(&1.account.payment_sources))

    {:ok, filtered}
  end

  defp active_payment_sources([]), do: false

  defp active_payment_sources(payment_sources) do
    ps =
      payment_sources
      |> Enum.filter(& &1.active)

    length(ps) >= 1
  end

  # To be updated when payment sources have a default boolean.
  def get_payment_source(payment_sources) do
    payment_sources
    |> Enum.filter(& &1.active)
    |> Enum.sort_by(& &1.inserted_at, {:desc, NaiveDateTime})
    |> List.first()
  end

  def get_tenant_balance(tenant_id) do
    AccountInfo.user_balance_total(tenant_id)
  end

  def get_tenant_from_list({:ok, tenants}), do: get_tenant_from_list(tenants)

  def get_tenant_from_list(tenants) do
    case length(tenants) do
      1 -> {:ok, List.first(tenants)}
      _ -> {:error, :multiple_tenants}
    end
  end

  defp gather_balance_data(tenant, _params) do
    balance = get_tenant_balance(tenant.id)
    {:ok, Map.merge(tenant, %{balance: balance})}
  end

  defp convert_balance_to_cents(balance) do
    Decimal.mult(balance, 100)
    |> Decimal.to_integer()
  end

  # -- Processing -----------
  def process_payment(%{balance: balance} = tenant, params) do
    case Decimal.cmp(balance, 0) do
      :eq -> {:error, :zero_balance}
      :lt -> {:error, :zero_balance}
      :gt -> actually_process(balance, tenant, params)
    end
  end

  # By this point, any tenants without an account or without an active payment source have already been filtered out.
  defp actually_process(balance, tenant, _params) do
    ps = get_payment_source(tenant.account.payment_sources)

    PaymentBoundary.create_payment(
      {tenant.account.id, "127.0.0.1", "text"},
      {convert_balance_to_cents(balance), ps.id, "TextPay Agreement Text"}
    )
  end

  defp handle_error(error, params) do
    case error do
      {:error, :zero_balance} ->
        zero_balance_reply(params)

      {:error, %AppCount.Core.RentSaga{message: "This transaction has been declined." <> _}} ->
        payment_declined_reply(params)

      _ ->
        generic_payment_error(params)
    end
  end

  # -- Replies -----------
  def unrecognized_reply(%{from_number: from_num, body: body}) do
    Logger.info("Unrecognized text from: #{from_num}: #{body}")

    {:ok, tenant} =
      get_tenant(from_num)
      |> get_tenant_from_list()

    {:ok, language} = get_language(tenant)

    reply = TextMessageTemplates.unrecognized_reply(language)
    SmsTopic.sms_requested(from_num, reply, __MODULE__)
  end

  def zero_balance_reply(%{from_number: from_num}) do
    {:ok, language} = get_language(from_num)

    reply = TextMessageTemplates.zero_balance_message(language)

    SmsTopic.sms_requested(from_num, reply, __MODULE__)
  end

  def generic_payment_error(%{from_number: from_num}) do
    {:ok, language} = get_language(from_num)

    reply = TextMessageTemplates.generic_payment_error(language)

    SmsTopic.sms_requested(from_num, reply, __MODULE__)
  end

  def payment_declined_reply(%{from_number: from_num}) do
    {:ok, language} = get_language(from_num)

    reply = TextMessageTemplates.payment_declined_error(language)

    SmsTopic.sms_requested(from_num, reply, __MODULE__)
  end

  def send_successful_payment(_tenant, %{from_number: from_num}) do
    {:ok, language} = get_language(from_num)

    reply = TextMessageTemplates.successful_payment(language)

    SmsTopic.sms_requested(from_num, reply, __MODULE__)
  end
end
