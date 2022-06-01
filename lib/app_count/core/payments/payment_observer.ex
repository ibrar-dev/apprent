defmodule AppCount.Core.PaymentObserver do
  @moduledoc false
  use GenServer
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.PaymentTopic
  alias AppCount.Core.PaymentObserver.State
  alias AppCount.Core.ClientSchema
  require Logger

  # --- CLIENT INTERFACE ----------------------------------
  def start_link([]) do
    state = %State{observer: __MODULE__}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def start_link(name: name) do
    state = %State{observer: __MODULE__}
    GenServer.start_link(__MODULE__, state, name: name)
  end

  #  --- SERVER INTERFACE -------------------------------------
  def init(%State{} = state) do
    AppCount.GenserverLogger.starting(__MODULE__)
    PaymentTopic.subscribe()
    {:ok, state}
  end

  # handle_info ---
  def handle_info(
        %DomainEvent{
          name: "payment_confirmed",
          content: %ClientSchema{name: client_schema, attrs: %{rent_saga_id: rent_saga_id}}
        },
        %State{observer: observer} = state
      ) do
    ClientSchema.new(client_schema, rent_saga_id)
    |> observer.do_payment_confirmed(state)

    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  # ------------  Implementation -----------------------

  def do_payment_confirmed(rent_saga_id, %State{} = state) do
    State.payment_confirmed(rent_saga_id, state)
  end
end
