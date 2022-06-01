defmodule AppCount.Core.Ports.TwilioPort do
  @moduledoc false
  use GenServer
  alias AppCount.Core.Ports.TwilioPort.State
  alias AppCount.Adapters.TwilioAdapter
  alias AppCount.Core.SmsTopic
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.PhoneNumber
  alias AppCount.Adapters.TwilioAdapterBehaviour.CreateMessageRequest
  alias AppCount.Messaging.Utils.TextMessageReplies
  alias AppCount.Twilio.Messaging
  alias AppCount.Messaging.TextMessageRepo

  require Logger

  defmodule State do
    @deps %{tenant_observer: AppCount.Core.TenantObserver}

    defstruct adapter: :no_adapter,
              deps: @deps,
              prev_result: {:none, "No SMS yet sent"}
  end

  # CLIENT INTERFACE --------------------------------------
  def start_link(name \\ __MODULE__) do
    AppCount.GenserverLogger.starting(__MODULE__)
    state = %State{}
    GenServer.start_link(__MODULE__, state, name: name)
  end

  # SERVER INTERFACE -------------------------------------

  def init(%State{} = state) do
    SmsTopic.subscribe()
    {:ok, state}
  end

  defp send_sms(%{phone_from: phone_from, phone_to: phone_to, message: message}) do
    adapter = adapter()

    request =
      CreateMessageRequest.new(message: message, phone_to: phone_to, phone_from: phone_from)

    request_spec = TwilioAdapter.request_spec(request: request)

    adapter.send_sms(request_spec)
    |> save_outgoing_sms()
  end

  def handle_info(
        %DomainEvent{
          name: "sms_requested",
          content: %{phone_to: phone_to, message: message, phone_from: phone_from}
        },
        %{deps: %{tenant_observer: tenant_observer}} = state
      ) do
    phone_to =
      phone_to
      |> PhoneNumber.new()
      |> PhoneNumber.dial_string()

    invalid =
      tenant_observer.invalid_phone_numbers()
      |> Enum.member?(phone_to)

    if invalid do
      Logger.info("#{__MODULE__} Skipping invalid number #{phone_to}")
    else
      send_sms(%{phone_from: phone_from, phone_to: phone_to, message: message})
    end

    {:noreply, state}
  end

  def handle_info(
        %DomainEvent{
          name: "message_received",
          content: %{phone_from: from, phone_to: to, params: params}
        },
        state
      ) do
    params
    |> Map.merge(%{from_number: from, to_number: to})
    |> TextMessageReplies.handle_message()

    {:noreply, state}
  end

  def handle_info(unexpected, %State{} = state) do
    Logger.error("#{__MODULE__}.handle_info() UNEXPECTED:  #{inspect(unexpected)}")
    {:noreply, state}
  end

  def adapter do
    Application.get_env(
      :app_count,
      TwilioAdapter,
      TwilioAdapter
    )
  end

  def save_outgoing_sms({:ok, text} = res) do
    Messaging.new_outgoing(text)
    |> Map.from_struct()
    |> TextMessageRepo.create()

    res
  end

  def save_outgoing_sms(res), do: res
end
