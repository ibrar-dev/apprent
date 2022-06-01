defmodule AppCount.Messaging.Utils.TextMessageSenders do
  @moduledoc """
  This is the module for all messages to be compiled and prepared prior to sending.

  In theory the Order observer would trigger a function from this file in order to send out any text.
  """
  alias AppCount.Messaging.Utils.TextMessageTemplates
  alias AppCount.Tenants.TenantRepo
  alias AppCount.Accounts.Utils.AccountInfo
  alias AppCount.Core.SmsTopic
  alias AppCount.Messaging.PhoneNumberRepo

  # -- API --------
  def offer_to_pay(tenant_id) when is_integer(tenant_id) do
    with {:ok, tenant} <- get_tenant(tenant_id),
         {:ok, payment_source} <- get_payment_source(tenant.account),
         {:ok, balance} <- get_balance(tenant.id),
         {:ok, property} <- get_property(tenant_id) do
      text_body =
        %{
          first_name: tenant.first_name,
          property_name: property.name,
          balance: balance,
          last_4: payment_source.last_4
        }
        |> TextMessageTemplates.offer_to_pay(tenant.account.preferred_language)

      property_phone = get_property_phone(property.id)

      SmsTopic.message_sent({property_phone, tenant.phone, text_body}, __MODULE__)
    else
      error_tuple ->
        error_tuple
    end
  end

  def offer_to_pay(tenant_id) when is_binary(tenant_id),
    do: offer_to_pay(String.to_integer(tenant_id))

  # Called from AppCount.Tasks.Workers.TextPayMonthlyOffer
  # Calling the above function in rapid succession caused the db to crash.
  def offer_to_pay(%{phone: phone, from: from, text_body: text_body, module: module}) do
    SmsTopic.message_sent({from, phone, text_body}, module)
  end

  # -- Fetching Helpers --------
  # Maybe these functions should be moved as this file will only continue to grow.
  # To be updated when payment sources have a default boolean.
  defp get_payment_source(account) do
    account.payment_sources
    |> Enum.filter(& &1.active)
    |> Enum.sort_by(& &1.inserted_at, {:desc, NaiveDateTime})
    |> List.first()
    |> case do
      nil -> {:error, "Missing Payment Source"}
      ps -> {:ok, ps}
    end
  end

  defp get_tenant(tenant_id) do
    TenantRepo.get_aggregate(tenant_id)
    |> case do
      nil -> {:error, "Invalid Tenant ID"}
      tenant -> validate_can_offer(tenant)
    end
  end

  defp validate_can_offer(tenant_aggregate) do
    with {:ok, account} <- has_account(tenant_aggregate.account),
         {:ok, _} <- able_to_message(account),
         {:ok, _} <- can_pay_online(tenant_aggregate.payment_status == "approved") do
      {:ok, tenant_aggregate}
    else
      error_tuple ->
        error_tuple
    end
  end

  defp has_account(nil), do: {:error, "No Account"}

  defp has_account(account), do: {:ok, account}

  defp able_to_message(%{allow_sms: true}), do: {:ok, nil}

  defp able_to_message(_), do: {:error, "SMS Not Allowed"}

  defp can_pay_online(false), do: {:error, "Payments Not Allowed"}

  defp can_pay_online(true), do: {:ok, nil}

  defp get_balance(tenant_id) do
    AccountInfo.user_balance_total(tenant_id)
    |> case do
      nil -> {:error, "Error getting balance"}
      balance -> compare_balance(balance)
    end
  end

  defp get_property(tenant_id) do
    TenantRepo.property_for_tenant(tenant_id)
    |> case do
      nil -> {:error, "Cannot Find Property"}
      property -> {:ok, property}
    end
  end

  defp get_property_phone(nil), do: nil

  defp get_property_phone(property_id) do
    PhoneNumberRepo.get_number(property_id, "payments")
    |> case do
      nil -> nil
      phone -> phone.number
    end
  end

  # -- Logic Helpers --------
  defp compare_balance(balance) do
    case Decimal.cmp(balance, 0) do
      :eq -> {:error, "Zero Balance"}
      :lt -> {:error, "Zero Balance"}
      :gt -> {:ok, balance}
    end
  end
end
