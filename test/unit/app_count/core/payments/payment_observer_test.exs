defmodule AppCount.Core.PaymentObserverTest do
  @moduledoc false
  use AppCount.Case, async: true
  alias AppCount.Core.PaymentObserver
  alias AppCount.Core.PaymentTopic
  alias AppCount.Core.PaymentObserver.State
  # import ExUnit.CaptureLog
  import ShorterMaps

  defmodule PaymentObserverParrot do
    @moduledoc false
    use TestParrot
    parrot(:observer, :do_payment_confirmed, :ok)
  end

  describe "start_link " do
    test ":ok pid", ~M[test] do
      # When
      assert {:ok, pid} = PaymentObserver.start_link(name: test)
      assert Process.alive?(pid)
      Process.exit(pid, :kill)
    end
  end

  describe "payment_confirmed handle_info() " do
    test "at least shows it compiles" do
      rent_saga_id = 42
      event = PaymentTopic.event(:payment_confirmed)
      schema = AppCount.Core.ClientSchema.new("dasmen", %{rent_saga_id: rent_saga_id})
      event = %{event | content: schema, source: __MODULE__}
      state = %State{observer: PaymentObserverParrot}

      # When
      {:noreply, _state} = PaymentObserver.handle_info(event, state)
      expected = AppCount.Core.ClientSchema.new("dasmen", rent_saga_id)
      # Then
      assert_receive {:do_payment_confirmed, ^expected, _state}
    end
  end

  describe "unexpected domain event in handle_info()" do
    test "it does not explode" do
      event = PaymentTopic.event(:payment_recorded)
      state = %State{}

      assert {:noreply, ^state} = PaymentObserver.handle_info(event, state)
    end
  end
end
