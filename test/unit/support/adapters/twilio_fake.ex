defmodule AppCount.Support.Adapters.TwilioFake do
  @moduledoc """
  Twilio Fake Adapter
  """
  alias AppCount.Adapters.TwilioAdapterBehaviour.CreateMessageResponse
  alias AppCount.Adapters.TwilioAdapterBehaviour
  alias AppCount.Core.Ports.RequestSpec
  require Logger
  @behaviour TwilioAdapterBehaviour

  @impl TwilioAdapterBehaviour
  def send_sms(%RequestSpec{request: request} = request_spec, _post_fn \\ &no_op/0) do
    Logger.error("FAKE Adapter --- Using #{__MODULE__}")
    send(self(), {:send_sms, request_spec})

    {:ok,
     %CreateMessageResponse{
       sid: "sid from #{__MODULE__}",
       to: request.phone_to,
       body: request.message,
       from: request.phone_from
     }}
  end

  @impl TwilioAdapterBehaviour
  def request_spec(overrides) when is_list(overrides) do
    params =
      [adapter: __MODULE__]
      |> Keyword.merge(overrides)

    struct(RequestSpec, params)
  end

  def no_op do
  end
end
