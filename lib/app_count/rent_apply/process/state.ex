defmodule AppCount.RentApply.Process.State do
  @enforce_keys [:property_id, :payment, :application, :ip_address]
  defstruct [
    :property_id,
    :payment,
    :application,
    :ip_address,
    :payment_process_result,
    :payment_insert_result,
    :application_process_result
  ]

  def new(property_id, payment_params, application_params, ip_address) do
    %__MODULE__{
      property_id: property_id,
      payment: payment_params,
      application: application_params,
      ip_address: ip_address
    }
  end

  def put_payment_process_result(result, state) do
    Map.put(state, :payment_process_result, result)
  end

  def put_payment_insert_result(result, state) do
    Map.put(state, :payment_insert_result, result)
  end

  def put_application_process_result(result, state) do
    Map.put(state, :application_process_result, result)
  end
end
