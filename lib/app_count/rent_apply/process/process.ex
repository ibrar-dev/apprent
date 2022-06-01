defmodule AppCount.RentApply.Process do
  alias AppCount.RentApply.Process.State
  alias AppCount.RentApply.Process.Payment
  alias AppCount.RentApply.Process.Notify
  alias AppCount.RentApply.Process.InsertPayment
  alias AppCount.RentApply.Process.Application

  def process(client_schema_name, property_id, payment_params, application_params, ip_address) do
    AppCount.Core.ClientSchema.new(client_schema_name, %{property_id: property_id})
    |> State.new(payment_params, application_params, ip_address)
    |> do_process_payment
    |> do_insert_payment
    |> do_process_application
    |> do_notify
  end

  def do_process_payment(%State{property_id: property_id, payment: payment} = state) do
    %{"amount" => amount, "token_description" => token_description, "token_value" => token_value} =
      payment

    Payment.process(property_id, amount, token_description, token_value)
    |> State.put_payment_process_result(state)
  end

  def do_insert_payment(%State{payment_process_result: {:error, e}}), do: {:error, e}

  def do_insert_payment(%State{payment_process_result: {:ok, _}} = state) do
    state
    |> InsertPayment.process()
    |> State.put_payment_insert_result(state)
  end

  def do_process_application(%State{payment_insert_result: {:ok, _}} = state) do
    state
    |> Application.process()
    |> State.put_application_process_result(state)
  end

  def do_process_application(%State{payment_insert_result: e}), do: e
  def do_process_application(e), do: e

  def do_notify(%State{application_process_result: {:ok, _}} = state) do
    Notify.notify(state)
    {:ok, state}
  end

  def do_notify(%State{application_process_result: e}), do: e
  def do_notify(e), do: e
end
