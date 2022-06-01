defmodule AppCount.Adapters.ZendeskAdapterBehaviour do
  alias AppCount.Core.Ports.RequestSpec

  defmodule CreateTicketRequest do
    defstruct [:subject, :description, :tags, :custom_fields]

    def new(jbody) do
      struct(__MODULE__, jbody)
    end
  end

  defmodule CreateTicketResponse do
    defstruct [
      :ticket
    ]

    def new(jbody) do
      struct(__MODULE__, jbody)
    end
  end

  # --------------- CALLBACKS ---------------------------------------------------------

  @callback create_ticket(RequestSpec.t(), (RequestSpec.t() -> any())) ::
              {:ok, CreateTicketResponse.t()} | {:error, term()}

  @callback request_spec(list()) :: RequestSpec.t()
end
