defmodule AppCount.Accounts.ProcessAutopay do
  import Ecto.Query
  use AppCount.Decimal
  alias AppCount.Repo
  alias AppCount.Accounts.Autopay
  alias AppCount.Accounts
  alias AppCount.Core.Clock
  alias AppCount.Core.ClientSchema
  require Logger

  # Day is an integer from 1-6
  def process(schema) do
    get_list_of_autopays(schema)
    |> Enum.each(&check_if_balance/1)
  end

  def get_list_of_autopays(schema) do
    from(
      a in Autopay,
      join: ac in assoc(a, :account),
      join: ps in assoc(a, :payment_source),
      where: a.active == true and ps.active,
      select: %{
        id: a.id,
        account_id: a.account_id,
        payment_source_id: a.payment_source_id,
        tenant_id: ac.tenant_id,
        property_id: ac.property_id,
        agreement_text: a.agreement_text,
        payer_ip_address: a.payer_ip_address,
        agreement_accepted_at: a.agreement_accepted_at
      }
    )
    |> Repo.all(prefix: schema)
  end

  # If a balance exists, kick off a payment. Otherwise, do nothing.
  def check_if_balance(%{tenant_id: tenant_id} = params) do
    # TODO:SCHEMA remove dasmen
    balance =
      Accounts.user_balance(ClientSchema.new("dasmen", tenant_id))
      |> Enum.reduce(0, &(&2 + &1.balance))

    cond do
      # AppRent sets a maximum payment amount of $3k - decline processing
      # autopay if that amount is exceeded
      balance > 0 && balance <= 3000 ->
        params
        |> Map.merge(%{balance: balance})
        |> process_with_rent_saga()

      # The amount exceeds what we can pay
      balance > 3000 ->
        params
        |> Map.merge(%{balance: balance})
        |> send_excessive_balance_notification()

      # No balance, thus no need to pay
      true ->
        nil
    end
  end

  def send_excessive_balance_notification(params) do
    error_path("Amount due exceeds maximum payment amount", params)
  end

  # {account_id, ip_address, "autopay"},
  # {amount_in_cents, payment_source_id, agreement_text}
  def process_with_rent_saga(
        %{
          account_id: account_id,
          payer_ip_address: payer_ip,
          payment_source_id: payment_source_id,
          agreement_text: agreement_text,
          id: id
        } = params
      ) do
    AppCount.Core.PaymentBoundary.create_payment(
      {account_id, payer_ip, "autopay"},
      {convert_to_cents(params.balance), payment_source_id, agreement_text}
    )
    |> case do
      {:ok, _rent_saga} ->
        update_last_run(id)

      {:error, %AppCount.Core.RentSaga{message: message}} when is_binary(message) ->
        error_path(message, params)

      {:error, message} when is_binary(message) ->
        error_path(message, params)

      unexpected_error ->
        Logger.error(inspect(unexpected_error))
        error_path(unexpected_error)
    end
  end

  def convert_to_cents(balance) do
    balance
    |> Decimal.from_float()
    |> Decimal.mult(100)
    |> Decimal.to_integer()
  end

  def error_path(_message, %{account_id: account_id} = params) do
    extra_data = get_extra_data(account_id)

    payment =
      %{
        amount: params.balance,
        attempt_time: Clock.now()
      }
      |> Map.merge(extra_data)

    AppCountCom.Accounts.unsuccessful_payment(payment, extra_data.property)
  end

  def error_path(unexpected_error) do
    # Unexpected Error
    Logger.error(inspect(unexpected_error))
  end

  def update_last_run(autopay_id) do
    Accounts.update_autopay(autopay_id, %{last_run: AppCount.current_time()})
  end

  def get_extra_data(account_id) do
    account = AppCount.Repo.get(AppCount.Accounts.Account, account_id)
    tenant = AppCount.Repo.get(AppCount.Tenants.Tenant, account.tenant_id)

    property = AppCount.Tenants.property_for(tenant.id)

    %{
      email: tenant.email,
      recipient_name: "#{tenant.first_name} #{tenant.last_name}",
      property: property
    }
  end
end
