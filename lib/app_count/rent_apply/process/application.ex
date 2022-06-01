defmodule AppCount.RentApply.Process.Application do
  alias AppCount.RentApply.Process.State
  alias AppCount.RentApply
  alias AppCount.Admins.Auth.Devices

  def process(%State{property_id: property_id, application: application} = state) do
    {:ok, inserts} = state.payment_insert_result

    params =
      application
      |> Map.put("payment_id", inserts.payment.id)
      |> Map.put("customer_ledger_id", inserts.ledger.id)
      |> verify_device

    RentApply.process_application(property_id, params)
    #    |> process_result(property_id, payment)
  end

  defp verify_device(%{"device_id" => device_id, "signed" => signed, "message" => msg} = p) do
    if Devices.verify_device(device_id, signed, msg) do
      p
    else
      Map.delete(p, "device_id")
    end
  end

  defp verify_device(p), do: Map.delete(p, "device_id")
end
