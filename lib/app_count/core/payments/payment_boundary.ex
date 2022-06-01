defmodule AppCount.Core.PaymentBoundary do
  @moduledoc """
  PaymentBoundary
  """
  alias AppCount.Core.RentSaga
  alias AppCount.Core.PaymentBoundaryBehaviour
  alias AppCount.Core.Ports.PaymentPort
  alias AppCount.Accounts.RentSagaRepo
  alias AppCount.Properties.PropertyRepo
  alias AppCount.Core.PaymentTopic
  alias AppCount.Core.Clock
  alias AppCount.Accounts.Utils.Payments
  alias AppCount.Core.ClientSchema
  require Logger
  @behaviour PaymentBoundaryBehaviour

  @thank_you_message "Succeeded"
  @last_attempt_at_least_this_long_ago {-1, :minutes}

  @deps %{
    port: PaymentPort,
    rent_saga_repo: RentSagaRepo,
    prop_repo: PropertyRepo,
    accounts: AppCount.Accounts
  }

  @impl PaymentBoundaryBehaviour
  def create_payment(
        {client_schema, account_id, ip_address, originating_device} = _system_params,
        {amount_in_cents, payment_source_id, agreement_text = _user_params}
      ) do
    with {:ok, account} <- load_account(ClientSchema.new(client_schema, account_id)),
         {:ok, true} <- account_not_locked?(ClientSchema.new(client_schema, account.id)),
         {:ok, prev_rent_saga} <-
           load_latest_rent_saga(ClientSchema.new(client_schema, account.id)),
         {:ok, true} <- allow_rent_saga_creation?(prev_rent_saga),
         {:ok, processors} <- load_processors(account),
         {:ok, true} <- verify_amount_presence(amount_in_cents),
         {:ok, rent_saga} <-
           create_rent_saga(
             account: account,
             processors: processors,
             ip_address: ip_address,
             amount_in_cents: amount_in_cents,
             agreement_text: agreement_text,
             originating_device: originating_device
           ),
         {:ok, rent_saga} <- select_payment_source(rent_saga, payment_source_id),
         {:ok, true} <- payment_source_not_locked?(rent_saga),
         {:ok, rent_saga} <- put_credit_card_surcharge(rent_saga),
         {:ok, rent_saga} <- post_payment(rent_saga),
         {:ok, rent_saga} <- lock_payment_source(rent_saga) do
      {:ok, rent_saga}
    else
      error_tuple ->
        error_tuple
    end
  end

  def verify_amount_presence(amount) when is_integer(amount) do
    {:ok, true}
  end

  def verify_amount_presence(_) do
    {:error, "You must provide a payment amount"}
  end

  def put_credit_card_surcharge(rent_saga, deps \\ @deps)

  def put_credit_card_surcharge(
        %{processor: %{type: "cc"}, amount_in_cents: amount_in_cents} = rent_saga,
        %{rent_saga_repo: rent_saga_repo}
      ) do
    cc_surcharge = Decimal.new("0.03")

    surcharge_in_cents =
      amount_in_cents
      |> Decimal.new()
      |> Decimal.mult(cc_surcharge)
      |> Decimal.round()
      |> Decimal.to_integer()

    rent_saga = update_surcharge_in_cents(rent_saga, surcharge_in_cents, rent_saga_repo)
    {:ok, rent_saga}
  end

  # If non-credit-card, do not apply a surcharge at all
  def put_credit_card_surcharge(rent_saga, _rent_saga_repo) do
    {:ok, rent_saga}
  end

  def put_cvv_confirmed_at(rent_saga, rent_saga_repo)

  # A card's CVV is confirmed at the time it is stored as a payment method,
  # or at the time it's used to make a payment (if a one-time payment). We
  # track this information as part of our efforts toward challenging chargebacks
  def put_cvv_confirmed_at(
        %{processor: %{type: "cc"}} = rent_saga,
        rent_saga_repo
      ) do
    rent_saga = update_cvv_confirmed_at(rent_saga, rent_saga_repo)
    rent_saga
  end

  # Non-CC payments do not have a CVV to confirm
  def put_cvv_confirmed_at(rent_saga, _repo) do
    rent_saga
  end

  def update_cvv_confirmed_at(rent_saga, rent_saga_repo) do
    %{payment_source: %{inserted_at: cvv_confirmed_at}} = rent_saga

    {:ok, rent_saga} = rent_saga_repo.update(rent_saga, %{cvv_confirmed_at: cvv_confirmed_at})
    rent_saga
  end

  def put_zip_code_confirmed_at(rent_saga, rent_saga_repo)

  # We confirm the zip code (via AVS) at the time a payment is submitted.
  def put_zip_code_confirmed_at(
        %{processor: %{type: "cc"}} = rent_saga,
        rent_saga_repo
      ) do
    rent_saga = update_zip_code_confirmed_at(rent_saga, rent_saga_repo)
    rent_saga
  end

  # We don't need zip code confirmation if it's not a credit card payment
  def put_zip_code_confirmed_at(rent_saga, _repo) do
    rent_saga
  end

  def update_zip_code_confirmed_at(rent_saga, rent_saga_repo) do
    zip_code_confirmed_at = Clock.now()

    {:ok, rent_saga} =
      rent_saga_repo.update(rent_saga, %{zip_code_confirmed_at: zip_code_confirmed_at})

    rent_saga
  end

  def load_account(account_id, %{rent_saga_repo: rent_saga_repo} \\ @deps) do
    rent_saga_repo.load_account(account_id)
  end

  def account_not_locked?(id, %{accounts: accounts} \\ @deps) do
    locked_account = accounts.account_lock_exists?(id)

    if locked_account do
      {:error,
       "Your payment cannot be processed because your online account is locked. You can submit payment using our MoneyGram partnership. Please contact the local leasing office if you have any questions or need further assistance."}
    else
      {:ok, true}
    end
  end

  def load_processors(%{property_id: property_id} = _account, %{prop_repo: prop_repo} \\ @deps) do
    processors = %{
      credit_card_processor_id: nil,
      bank_account_processor_id: nil
    }

    processors =
      case prop_repo.credit_card_payment_processor(property_id) do
        {:ok, credit_card_processor} ->
          %{processors | credit_card_processor_id: credit_card_processor.id}

        _ ->
          processors
      end

    processors =
      case prop_repo.bank_account_payment_processor(property_id) do
        {:ok, bank_account_processor} ->
          %{processors | bank_account_processor_id: bank_account_processor.id}

        _ ->
          processors
      end

    {:ok, processors}
  end

  def create_rent_saga(
        [
          account: account,
          processors: processors,
          ip_address: ip_address,
          amount_in_cents: amount_in_cents,
          agreement_text: agreement_text,
          originating_device: originating_device
        ],
        %{rent_saga_repo: rent_saga_repo} \\ @deps
      ) do
    rent_saga_repo.create_session(account, %{
      credit_card_processor_id: processors.credit_card_processor_id,
      bank_account_processor_id: processors.bank_account_processor_id,
      ip_address: ip_address,
      started_at: DateTime.utc_now(),
      amount_in_cents: amount_in_cents,
      agreement_text: agreement_text,
      originating_device: originating_device,
      property_id: account.property_id
    })
    |> load_aggregate(rent_saga_repo)
  end

  defp load_aggregate({:error, _} = error_tuple, _repo) do
    error_tuple
  end

  defp load_aggregate({:ok, rent_saga}, rent_saga_repo) do
    payment_sesssion = rent_saga_repo.get_aggregate(rent_saga.id)
    {:ok, payment_sesssion}
  end

  def load_latest_rent_saga(account_id, %{rent_saga_repo: rent_saga_repo} \\ @deps) do
    {:ok, rent_saga_repo.load_latest(account_id)}
  end

  def allow_rent_saga_creation?(rent_saga, deps \\ @deps)

  def allow_rent_saga_creation?(nil, _deps) do
    # there was no latest_rent_saga
    {:ok, true}
  end

  def allow_rent_saga_creation?(
        %{started_at: last_attempt_started_at} = latest_rent_saga,
        %{rent_saga_repo: rent_saga_repo}
      ) do
    last_attempt_time_limit_at = Clock.now(@last_attempt_at_least_this_long_ago)

    if last_attempt_started_at |> Clock.less_than(last_attempt_time_limit_at) do
      {:ok, true}
    else
      update_message(latest_rent_saga, "denied attempt #{Clock.now()}", rent_saga_repo)
      {:error, "Please wait a few minutes and then try your payment again"}
    end
  end

  def select_payment_source(
        %RentSaga{
          id: id,
          account: %{property_id: property_id}
        },
        payment_source_id,
        %{rent_saga_repo: rent_saga_repo} \\ @deps
      ) do
    rent_saga =
      rent_saga_repo.get_aggregate(id)
      |> update_payment_source(payment_source_id, rent_saga_repo)
      |> rent_saga_repo.get_aggregate()
      |> select_processor(rent_saga_repo)
      |> update_processor(rent_saga_repo)
      |> rent_saga_repo.get_aggregate()

    if rent_saga.failed_at == nil do
      {:ok, rent_saga}
    else
      {:error, "select_payment_source failed for Property: #{property_id} RentSaga: #{id}"}
    end
  end

  def payment_source_not_locked?(rent_saga) do
    source = rent_saga.payment_source

    locked = Payments.payment_source_in_cooldown?(source)

    if locked do
      {:error, "Payment source locked, as it has been used in the last 12 hours"}
    else
      {:ok, true}
    end
  end

  def lock_payment_source(%{payment_source_id: payment_source_id} = rent_saga) do
    Payments.lock_and_return_source(payment_source_id)

    {:ok, rent_saga}
  end

  def select_processor(%{payment_source: payment_source} = rent_saga, rent_saga_repo) do
    processor =
      case payment_source.type do
        "cc" -> rent_saga.credit_card_processor
        "ba" -> rent_saga.bank_account_processor
      end

    if processor == nil do
      message = "Processor #{payment_source.type} not found for property"

      rent_saga =
        rent_saga
        |> update_failed_at(rent_saga_repo)
        |> update_message(message, rent_saga_repo)

      {rent_saga, nil}
    else
      {rent_saga, processor.id}
    end
  end

  def post_payment(_, deps \\ @deps)

  def post_payment(
        %RentSaga{payment_source_id: :not_set} = rent_saga,
        %{rent_saga_repo: rent_saga_repo}
      ) do
    rent_saga =
      update_message(rent_saga, "Payment declined - select a payment source", rent_saga_repo)

    {:error, rent_saga}
  end

  # Handle no amount or non-positive amount
  def post_payment(%RentSaga{amount_in_cents: amount_in_cents} = rent_saga, %{
        rent_saga_repo: rent_saga_repo
      })
      when is_nil(amount_in_cents) or amount_in_cents <= 0 do
    rent_saga =
      update_message(rent_saga, "Payment declined - amount must be positive", rent_saga_repo)

    {:error, rent_saga}
  end

  def post_payment(%RentSaga{amount_in_cents: amount_in_cents} = rent_saga, %{
        rent_saga_repo: rent_saga_repo
      })
      when amount_in_cents > 300_000 do
    rent_saga =
      update_message(rent_saga, "Payment declined - amount must be $3000 or less", rent_saga_repo)

    {:error, rent_saga}
  end

  def post_payment(
        %RentSaga{amount_in_cents: amount_in_cents, surcharge_in_cents: surcharge_in_cents} =
          rent_saga,
        %{rent_saga_repo: rent_saga_repo, port: port}
      ) do
    rent_saga =
      %RentSaga{payment_source: payment_source, processor: processor} =
      rent_saga_repo.get_aggregate(rent_saga)

    total_amount_in_cents = amount_in_cents + surcharge_in_cents

    dollar_amount = total_amount_in_cents / 100

    result = port.process_payment(dollar_amount, payment_source, processor)

    # TODO move error handling to adapter
    ok_error_tuple =
      case result do
        {:ok, %{transaction_id: transaction_id} = response} ->
          rent_saga =
            rent_saga
            |> update_payment_confirmed_at(rent_saga_repo)
            |> update_transaction_id(transaction_id, rent_saga_repo)
            |> put_zip_code_confirmed_at(rent_saga_repo)
            |> put_cvv_confirmed_at(rent_saga_repo)
            |> update_amount_in_cents(amount_in_cents, rent_saga_repo)
            |> update_total_amount_in_cents(total_amount_in_cents, rent_saga_repo)
            |> update_message(@thank_you_message, rent_saga_repo)
            |> update_response_from_adapter(response, rent_saga_repo)
            |> payment_confirmed_event()

          {:ok, rent_saga}

        {:error, message} when is_binary(message) ->
          handle_payment_error(message, rent_saga, rent_saga_repo)

        {:error, %{reason: :timeout}} ->
          handle_payment_error("Payment declined - server timeout", rent_saga, rent_saga_repo)

        {:error, %{reason: message}} when is_binary(message) ->
          handle_payment_error(message, rent_saga, rent_saga_repo)
      end

    ok_error_tuple
  end

  defp handle_payment_error(message, rent_saga, rent_saga_repo) do
    rent_saga =
      rent_saga
      |> update_failed_at(rent_saga_repo)
      |> update_message(message, rent_saga_repo)

    {:error, rent_saga}
  end

  defp payment_confirmed_event(rent_saga) do
    ClientSchema.new(rent_saga.__meta__.prefix, %{rent_saga_id: rent_saga.id})
    |> PaymentTopic.payment_confirmed(__MODULE__)

    rent_saga
  end

  defp update_processor({rent_saga, processor_id}, rent_saga_repo) do
    {:ok, rent_saga} = rent_saga_repo.update(rent_saga, %{processor_id: processor_id})
    rent_saga
  end

  defp update_payment_source(rent_saga, payment_source_id, rent_saga_repo) do
    {:ok, rent_saga} = rent_saga_repo.update(rent_saga, %{payment_source_id: payment_source_id})
    rent_saga
  end

  defp update_transaction_id(rent_saga, transaction_id, rent_saga_repo) do
    {:ok, rent_saga} = rent_saga_repo.update(rent_saga, %{transaction_id: transaction_id})
    rent_saga
  end

  defp update_amount_in_cents(rent_saga, amount_in_cents, rent_saga_repo) do
    {:ok, rent_saga} = rent_saga_repo.update(rent_saga, %{amount_in_cents: amount_in_cents})
    rent_saga
  end

  # refactor later
  def update_message(%{message: prev_message} = rent_saga, new_message, rent_saga_repo) do
    updated_message =
      if prev_message == "" do
        new_message
      else
        "#{prev_message}; #{new_message}"
      end

    {:ok, rent_saga} = rent_saga_repo.update(rent_saga, %{message: updated_message})
    rent_saga
  end

  defp update_payment_confirmed_at(rent_saga, rent_saga_repo) do
    {:ok, rent_saga} =
      rent_saga_repo.update(rent_saga, %{payment_confirmed_at: DateTime.utc_now()})

    rent_saga
  end

  def update_failed_at(%{failed_at: nil} = rent_saga, rent_saga_repo) do
    {:ok, rent_saga} = rent_saga_repo.update(rent_saga, %{failed_at: DateTime.utc_now()})

    rent_saga
  end

  def update_failed_at(%{failed_at: %DateTime{}} = rent_saga, _repo) do
    # already set, skip the rest
    rent_saga
  end

  def update_surcharge_in_cents(rent_saga, surcharge_in_cents, rent_saga_repo) do
    {:ok, rent_saga} = rent_saga_repo.update(rent_saga, %{surcharge_in_cents: surcharge_in_cents})

    rent_saga
  end

  def update_total_amount_in_cents(rent_saga, total_amount_in_cents, rent_saga_repo) do
    {:ok, rent_saga} =
      rent_saga_repo.update(rent_saga, %{total_amount_in_cents: total_amount_in_cents})

    rent_saga
  end

  def update_response_from_adapter(rent_saga, response_from_adapter, rent_saga_repo) do
    {:ok, rent_saga} =
      rent_saga_repo.update(rent_saga, %{response_from_adapter: inspect(response_from_adapter)})

    rent_saga
  end
end
