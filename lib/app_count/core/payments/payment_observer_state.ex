defmodule AppCount.Core.PaymentObserver.State do
  @moduledoc false
  alias AppCount.Core.PaymentObserver.State
  alias AppCount.Accounts.RentSagaRepo
  alias AppCount.Ledgers.Batch
  alias AppCount.Repo
  alias AppCount.Core.ClientSchema
  require Logger

  @deps %{
    # TODO rename to "rent_saga_repo"
    repo: RentSagaRepo,
    tenant_repo: AppCount.Tenants.TenantRepo,
    prop_repo: AppCount.Properties.PropertyRepo,
    tell_yardi_fn: &__MODULE__.tell_yardi/1,
    tell_accounting_fn: &__MODULE__.tell_accounting/1,
    send_receipt_to_tenant_fn: &__MODULE__.tell_resident/1
  }

  defstruct observer: :not_set, deps: @deps

  def payment_confirmed(
        %ClientSchema{name: client_schema, attrs: rent_saga_id},
        %State{deps: %{repo: repo, prop_repo: prop_repo} = deps} = _state
      ) do
    with {:ok, rent_saga} <- repo.aggregate(rent_saga_id),
         {:ok, account} <-
           repo.load_account(ClientSchema.new(client_schema, rent_saga.account_id)),
         setting <- prop_repo.setting(account.property_id),
         tenant <- deps.tenant_repo.get(account.tenant_id),
         {:ok, context} <- load_context(rent_saga, account, tenant, setting, repo),
         {:ok, _setting} <- property_accepting_payments(setting),
         {:ok, batch} <- create_batch(context),
         {:ok, payment} <- create_accounting_payment(context, batch),
         {:ok, _rent_saga} <- repo.update(rent_saga, %{payment_id: payment.id}) do
      context
      |> Map.put(:payment, payment)
      |> notify_yardi(deps)
      |> notify_accounting(deps)
      |> send_receipt_to_tenant(deps)

      :ok
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        log_and_return_error("FAILURE #{inspect(changeset.errors)}", rent_saga_id, repo)

      error ->
        log_and_return_error("FAILURE #{inspect(error)}", rent_saga_id, repo)
    end
  end

  defp log_and_return_error(error_message, rent_saga_id, repo) do
    Logger.error(error_message)
    update_message(rent_saga_id, error_message, repo)
    {:error, error_message}
  end

  defp send_receipt_to_tenant(context, deps) do
    deps.send_receipt_to_tenant_fn.(context)

    context
  end

  defp notify_yardi(%{rent_saga: rent_saga} = context, deps) do
    if is_this_for_yardi?(context) do
      deps.tell_yardi_fn.(context)
      update_yardi_notified_at(rent_saga)
    end

    context
  end

  # Notify resident, others, via email
  defp notify_accounting(%{rent_saga: rent_saga} = context, _deps) do
    # Comment out because we are NOT connecting to SOFTLEDGER
    # if :ok == deps.tell_accounting_fn.(context) do
    #   update_accounting_notified_at(rent_saga)
    # end
    # Just act as if we notified accounting
    update_accounting_notified_at(rent_saga)

    context
  end

  defp publish_payment_recorded(
         %{rent_payment_id: _rent_payment_id, account_id: _account_id, line_items: _line_items} =
           content
       ) do
    AppCount.Core.PaymentTopic.payment_recorded(content, __MODULE__)
  end

  def is_this_for_yardi?(%{
        tenant_external_id: tenant_external_id,
        sync_payments: true,
        integration: "Yardi",
        payment: _payment
      })
      when is_binary(tenant_external_id) do
    true
  end

  def is_this_for_yardi?(_otherwise) do
    false
  end

  defp property_accepting_payments(%{payments_accepted: true} = settings) do
    {:ok, settings}
  end

  # property not accepting payments
  defp property_accepting_payments(_settings) do
    error_message = "Property not accepting payments"
    {:error, error_message}
  end

  # setting is nil
  def load_context(rent_saga, _account, _tenant, nil, repo) do
    error_message = "Missing Parameter setting is nil"
    update_message(rent_saga, error_message, repo)
    {:error, error_message}
  end

  # tenant is nil
  def load_context(rent_saga, _account, nil, _setting, repo) do
    error_message = "Missing Parameter tenant is nil"
    update_message(rent_saga, error_message, repo)
    {:error, error_message}
  end

  def load_context(rent_saga, account, tenant, setting, _repo)
      when not is_nil(tenant) and not is_nil(setting) do
    context = %{
      client_schema: rent_saga.__meta__.prefix,
      account: account,
      default_bank_account_id: setting.default_bank_account_id,
      integration: setting.integration,
      rent_saga: rent_saga,
      property_id: account.property_id,
      sync_payments: setting.sync_payments,
      tenant: tenant,
      tenant_external_id: tenant.external_id
    }

    {:ok, context}
  end

  def create_batch(%{
        property_id: property_id,
        default_bank_account_id: default_bank_account_id
      }) do
    Batch.changeset(%Batch{}, %{
      property_id: property_id,
      bank_account_id: default_bank_account_id
    })
    |> Repo.insert()
  end

  def create_accounting_payment(
        %{
          rent_saga: %{
            amount_in_cents: amount_in_cents,
            payment_source_id: payment_source_id,
            transaction_id: transaction_id,
            ip_address: ip_address,
            started_at: started_at,
            payment_source: payment_source,
            surcharge_in_cents: surcharge_in_cents,
            agreement_text: agreement_text,
            originating_device: originating_device,
            cvv_confirmed_at: cvv_confirmed_at,
            zip_code_confirmed_at: zip_code_confirmed_at
          },
          property_id: property_id,
          tenant: tenant
        },
        batch
      ) do
    # TODO:SCHEMA remove dasmen
    AppCount.Ledgers.Utils.Payments.create_payment(
      ClientSchema.new("dasmen", %{
        agreement_text: agreement_text,
        agreement_accepted_at: started_at,
        payer_ip_address: ip_address,
        description: "AppRent Payment",
        source: originating_device || "web",
        response: %{not_used: true},
        transaction_id: transaction_id,
        amount: Decimal.div(amount_in_cents, 100),
        surcharge: Decimal.div(surcharge_in_cents, 100),
        tenant_id: tenant.id,
        property_id: property_id,
        payment_source_id: payment_source_id,
        batch_id: batch.id,
        last_4: payment_source.last_4,
        payer_name: payment_source.name,
        payment_type: payment_source.type,
        cvv_confirmed_at: cvv_confirmed_at,
        zip_code_confirmed_at: zip_code_confirmed_at
      })
    )
  end

  def tell_yardi(%{payment: payment}) do
    AppCount.Yardi.ExportPayment.export_payment(payment.id)
    :ok
  end

  # Tell the resident
  def tell_resident(%{
        client_schema: client_schema,
        payment: payment,
        tenant: tenant,
        property_id: property_id
      }) do
    AppCountCom.Accounts.payment_received_by_property_id(
      tenant,
      payment,
      property_id,
      client_schema,
      &AppCount.Properties.get_property/1
    )

    :ok
  end

  # Post to the accounting system
  def tell_accounting(%{rent_saga: %{account_id: account_id, payment_id: payment_id}}) do
    #
    # WIP, TODO, FIXME  David or Yousef need to provide items with accounts for recording the payment
    #
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
      account_id: account_id,
      rent_payment_id: payment_id
    }

    publish_payment_recorded(content)

    :ok
  end

  def update_accounting_notified_at(rent_saga, %{repo: repo} \\ @deps) do
    {:ok, rent_saga} = repo.update(rent_saga, %{accounting_notified_at: DateTime.utc_now()})

    rent_saga
  end

  def update_yardi_notified_at(rent_saga, %{repo: repo} \\ @deps) do
    {:ok, rent_saga} = repo.update(rent_saga, %{yardi_notified_at: DateTime.utc_now()})

    rent_saga
  end

  def update_message(rent_saga_id, new_message, repo) when is_integer(rent_saga_id) do
    if rent_saga = repo.get_aggregate(rent_saga_id) do
      update_message(rent_saga, new_message, repo)
      :ok
    else
      message = "NOT FOUND rent_saga_id:#{rent_saga_id} message: #{new_message}"
      Logger.error(message)
      {:error, message}
    end
  end

  def update_message(%{message: prev_message} = rent_saga, new_message, repo) do
    updated_message =
      if prev_message == "" do
        new_message
      else
        "#{prev_message}; #{new_message}"
      end

    {:ok, rent_saga} = repo.update(rent_saga, %{message: updated_message})
    rent_saga
  end
end
