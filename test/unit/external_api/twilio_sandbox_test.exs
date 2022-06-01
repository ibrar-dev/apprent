defmodule AppCount.ExternalApi.TwilioSandboxApiTest do
  #
  #  mix test test/external_api --include external_api
  #
  # This test hits the external Twilio API using sandbox credentials. We
  # should run this only on-demand, rather than all the time, but we can use it
  # to test our API integrations end-to-end and verify functionality against the
  # actual service.
  #
  # These tests are excluded by default. To run them, do something like this:
  # mix test --include external_api
  #
  # This keeps us from hammering Twilio too badly and also keeps our test
  # suite slightly less slow than it otherwise might be.

  use AppCount.Case
  alias AppCount.Adapters.TwilioAdapter
  alias AppCount.Adapters.TwilioAdapter.Service
  alias AppCount.Adapters.TwilioAdapterBehaviour.CreateMessageRequest
  alias AppCount.Adapters.TwilioAdapterBehaviour.CreateMessageResponse

  @moduletag :external_api

  # ref: https://www.twilio.com/docs/iam/test-credentials

  setup do
    on_exit(fn -> ExternalService.reset_fuse(Service) end)
    :ok
  end

  describe "send_sms using real API" do
    test "client call to Twilio sandbox" do
      message = "Hello World"
      phone_to = "+15005551111"
      request = CreateMessageRequest.new(message: message, phone_to: phone_to)

      # When
      {:ok, create_message_response} = TwilioAdapter.send_sms(request)

      assert %CreateMessageResponse{} = create_message_response

      assert create_message_response.sid
      refute create_message_response.error_code
      assert create_message_response.body == "Hello World"
    end
  end
end
