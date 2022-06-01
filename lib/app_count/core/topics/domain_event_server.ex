defmodule AppCount.Core.DomainEventServer do
  @moduledoc """
  Listens to various topics
  When a DomainEvent is received, stores it into the DB

  What this means is that if you want the traffic on a topic stored,
  You must subscribe to that topic in this GenServer

  """

  use GenServer
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.DomainEventRepo

  require Logger

  @production_topics [
    AppCount.Accounting.ExternalLedgers.Publishers.PropertyTopic,
    AppCount.Core.CardItemTopic,
    AppCount.Core.CardTopic,
    AppCount.Core.LogTopic,
    AppCount.Core.OrderTopic,
    AppCount.Core.SmsTopic
  ]

  # --- CLIENT INTERFACE --------------------------------------
  def start_link([]) do
    state = %{deps: %{repo: DomainEventRepo}}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def start_link(name: name) do
    state = %{}
    GenServer.start_link(__MODULE__, state, name: name)
  end

  #  --- SERVER INTERFACE -------------------------------------
  def init(state) do
    topics = Application.get_env(:app_count, :topics_to_store, @production_topics)
    Enum.each(topics, fn topic -> topic.subscribe() end)
    {:ok, state}
  end

  # handle_info ---
  def handle_info(
        %DomainEvent{topic: "database", name: "saved"},
        state
      ) do
    # always skip database topic events
    {:noreply, state}
  end

  def handle_info(%DomainEvent{} = domain_event, %{deps: %{repo: repo}} = state) do
    repo.store(domain_event)
    {:noreply, state}
  end
end
