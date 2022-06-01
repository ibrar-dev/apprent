defmodule AppCount.RentApply.Process.Notify do
  alias AppCount.RentApply.Process.State
  alias AppCount.RentApply
  require Logger

  def notify(%State{application_process_result: result, property_id: property_id} = state) do
    {:ok, %{payment: payment}} = state.payment_insert_result

    case result do
      {:ok, result, :instant_screen} ->
        AppCount.Core.Tasker.start(RentApply, :send_confirmation, [result, property_id, payment])

      {:ok, result} ->
        AppCount.Core.Tasker.start(RentApply, :notify_admins, [result, property_id])
        AppCount.Core.Tasker.start(RentApply, :send_confirmation, [result, property_id, payment])

      {:error, %{application: _app} = result} ->
        AppCount.Core.Tasker.start(RentApply, :notify_admins, [result, property_id])

      unexpected ->
        "#{__MODULE__}.notify #{inspect(unexpected)}"
        |> Logger.error()
    end
  end
end
