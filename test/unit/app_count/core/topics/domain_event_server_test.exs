defmodule AppCount.Core.DomainEventServerTest do
  use AppCount.Case, async: true
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.DomainEventServer

  defmodule DomainEventServerParrot do
    use TestParrot
    #       scope     funtion   default-returns-value
    parrot(:repo, :store, :ok)
  end

  describe "start_link " do
    test ":ok pid", ~M[test] do
      # When
      assert {:ok, pid} = DomainEventServer.start_link(name: test)
      assert Process.alive?(pid)
      Process.exit(pid, :kill)
    end
  end

  test "handle_info(event, state)" do
    state = %{deps: %{repo: DomainEventServerParrot}}

    event = %DomainEvent{
      topic: "DomainEventServerTest",
      name: "storage-test",
      content: %{test: "test"},
      source: __MODULE__
    }

    # When
    {:noreply, _state} = DomainEventServer.handle_info(event, state)

    assert_receive {:store, ^event}
  end

  test "Skip DB. handle_info(%DomainEvent{topic: database, name: saved}, state)" do
    state = %{deps: %{repo: DomainEventServerParrot}}

    event = %DomainEvent{
      topic: "database",
      name: "saved",
      content: %{test: "test"},
      source: __MODULE__
    }

    # When
    {:noreply, _state} = DomainEventServer.handle_info(event, state)

    refute_receive {:store, ^event}
  end
end
