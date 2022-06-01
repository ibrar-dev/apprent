defmodule AppCount.Case do
  @moduledoc """

  You may define functions here to be used as helpers in
  your tests.

  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnit.Case
      alias AppCount.Support.AppTime
      alias AppCount.Core.Clock
      import ShorterMaps
      import ExUnit.CaptureLog
      import AppCount.Case.Helper
    end
  end

  defmodule Helper do
    def naive_now do
      # NOTE: NaiveDateTime assumes UTC timezone
      NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    end

    @doc """
    A helper that transform changeset errors to a map of messages.

    assert {:error, changeset} = Accounts.create_user(%{password: "short"})
    assert "password is too short" in errors_on(changeset).password
    assert %{password: ["password is too short"]} = errors_on(changeset)

    """
    def errors_on(%Ecto.Changeset{} = changeset) do
      Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
        Enum.reduce(opts, message, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)
    end

    # Given a changeset, assert validity. Prints errors as message
    def assert_valid(%Ecto.Changeset{} = changeset) do
      assert(changeset.valid?, changeset |> errors_on() |> inspect())
    end

    # Given a changeset, refute validity. Prints changeset at large as message
    def refute_valid(%Ecto.Changeset{} = changeset) do
      refute(changeset.valid?, changeset |> inspect())
    end

    def monday_noon do
      ~N[2020-09-21 12:00:00]
      |> DateTime.from_naive!("Etc/UTC")
    end

    def friday_noon do
      ~N[2020-09-25 12:00:00]
      |> DateTime.from_naive!("Etc/UTC")
    end
  end
end
