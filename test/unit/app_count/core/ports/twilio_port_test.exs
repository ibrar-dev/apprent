defmodule AppCount.Core.Ports.TwilioPortTest do
  use AppCount.Case, async: true
  alias AppCount.Core.Ports.TwilioPort
  alias AppCount.Core.Ports.TwilioPort.State
  alias AppCount.Core.SmsTopic
  alias AppCount.Adapters.TwilioAdapterBehaviour.CreateMessageRequest

  import ShorterMaps

  defmodule AdapterParrot do
    @behaviour AppCount.Adapters.TwilioAdapterBehaviour
    use TestParrot
    parrot(:adapter, :send_sms, {:ok, "Some Response"})
    parrot(:adapter, :request_spec, %AppCount.Core.Ports.RequestSpec{})
  end

  defmodule TenantObserverParrot do
    use TestParrot
    parrot(:observer, :invalid_phone_numbers, [])
  end

  describe "start_link " do
    test ":ok pid", ~M[test] do
      # When
      assert {:ok, pid} = TwilioPort.start_link(test)
      assert Process.alive?(pid)
      Process.exit(pid, :kill)
    end
  end

  describe "handle sms_requested" do
    test "send" do
      state = %State{adapter: AdapterParrot}
      content = %{phone_to: "+15135551234", message: "test_message", phone_from: nil}
      event = %{SmsTopic.event(:sms_requested) | content: content, source: __MODULE__}
      expected_request = %CreateMessageRequest{message: "test_message", phone_to: "+15135551234"}

      expected_request_spec = %AppCount.Core.Ports.RequestSpec{
        adapter: AppCount.Adapters.TwilioAdapter,
        request: expected_request,
        returning: :not_set,
        token: :not_set,
        url: :not_set,
        verb: :not_set
      }

      # When
      {:noreply, _state} = TwilioPort.handle_info(event, state)

      assert_receive {:send_sms, ^expected_request_spec}
    end

    test "skip invalid_phone" do
      invalid_phone = "+15135551234"
      TenantObserverParrot.say_invalid_phone_numbers([invalid_phone])
      state = %State{adapter: AdapterParrot, deps: %{tenant_observer: TenantObserverParrot}}
      content = %{phone_to: invalid_phone, message: "test_message", phone_from: nil}
      event = %{SmsTopic.event(:sms_requested) | content: content, source: __MODULE__}

      # When
      {:noreply, _state} = TwilioPort.handle_info(event, state)

      refute_receive {:send_sms, _ignored}
    end
  end
end
