defmodule AppCount.RentApply.Process.NotifyTest do
  use AppCount.Case
  alias AppCount.RentApply.Process.State
  alias AppCount.RentApply.Process.Notify

  def state_with_result(process_result) do
    %State{
      property_id: 222,
      application: %{},
      payment: %{},
      ip_address: "1.1.1.1",
      payment_insert_result: {:ok, %{payment: %{amount: 200}}},
      application_process_result: process_result
    }
  end

  describe "notify/1" do
    test "start " do
      {:ok, "result", :instant_screen}
      |> state_with_result
      |> Notify.notify()

      refute_receive {:start, AppCount.RentApply, :notify_admins, ["result", 222]}

      assert_receive {:start, AppCount.RentApply, :send_confirmation,
                      ["result", 222, %{amount: 200}]}
    end

    test ":ok, notify_admins /  send_confirmation" do
      {:ok, "result"}
      |> state_with_result
      |> Notify.notify()

      assert_receive {:start, AppCount.RentApply, :notify_admins, ["result", 222]}

      assert_receive {:start, AppCount.RentApply, :send_confirmation,
                      ["result", 222, %{amount: 200}]}
    end

    test ":error, notify_admins " do
      {:error, :documents, "changeset"}

      state =
        {:error, :documents, "changeset"}
        |> state_with_result

      log_messages =
        capture_log(fn ->
          Notify.notify(state)
        end)

      assert log_messages =~
               "Elixir.AppCount.RentApply.Process.Notify.notify {:error, :documents,"
    end
  end
end
