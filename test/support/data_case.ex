defmodule AppCount.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias AppCount.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import AppCount.DataCase
      import ShorterMaps
      import AppCount.Factory
      import ExUnit.CaptureLog

      alias AppCount.Support.AppTime
      alias AppCount.Core.Clock
      alias AppCount.Factory
      alias AppCount.DataCase.GenericRepoParrot
      alias AppCount.Support.PropertyBuilder, as: PropBuilder
      import AppCount.Case.Helper
    end
  end

  setup(_tags) do
    load_ecto_sandbox()
    # OR
    # load_ecto_new_style_sandbox(tags)
    AppCount.Admins.AccessServer.clear()
    :ok
  end

  def subscribe(topic_module) do
    topic_module.subscribe()
    on_exit(fn -> AppCount.Core.EventBus.unsubscribe(topic_module.topic()) end)
  end

  def load_ecto_sandbox do
    Ecto.Adapters.SQL.Sandbox.checkout(AppCount.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(AppCount.Repo, {:shared, self()})
  end

  def load_ecto_new_style_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(LiveViewStudio.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  defmodule GenericRepoParrot do
    @moduledoc """
    Parrot of the functions for a GenericRepo
    to change the return values, use GenericRepoParrot.say_something()
    like:
      GenericRepoParrot.say_all([%{id: 1}, %{id: 2}])
      After that all/0 will return [%{id: 1}, %{id: 2}]
    Remember Parrots only work in a single process.
    """
    use TestParrot
    parrot(:repo, :all, [])
    parrot(:repo, :get_by, nil)
    parrot(:repo, :get, nil)
    parrot(:repo, :get_aggregate, nil)
    parrot(:repo, :insert, {:ok, %{}})
    parrot(:repo, :update, {:ok, %{}})
    parrot(:repo, :delete, {:ok, "successfully deleted"})
    parrot(:repo, :count, -1)
    parrot(:repo, :one, %{})
    parrot(:repo, :first, %{})
  end
end
