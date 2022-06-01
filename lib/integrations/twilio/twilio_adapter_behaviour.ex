defmodule AppCount.Adapters.TwilioAdapterBehaviour do
  alias AppCount.Core.Ports.RequestSpec

  defmodule CreateMessageRequest do
    defstruct [:message, :phone_to, :phone_from, :data]

    def new(jbody) do
      struct(__MODULE__, jbody)
    end
  end

  defmodule CreateMessageResponse do
    defstruct [
      :sid,
      :date_created,
      :date_updated,
      :date_sent,
      :account_sid,
      :to,
      :from,
      :messaging_service_sid,
      :body,
      :status,
      :num_segments,
      :num_media,
      :direction,
      :api_version,
      :price,
      :price_unit,
      :error_code,
      :error_message,
      :uri,
      :subresource_url
    ]

    def new(jbody) do
      struct(__MODULE__, jbody)
    end
  end

  # --------------- CALLBACKS ---------------------------------------------------------

  @callback send_sms(RequestSpec.t(), (RequestSpec.t() -> any())) ::
              {:ok, CreateMessageResponse.t()} | {:error, term()}

  @callback request_spec(list()) :: RequestSpec.t()
end
