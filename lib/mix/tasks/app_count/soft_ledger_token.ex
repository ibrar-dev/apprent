defmodule Mix.Tasks.AppCount.SoftLedgerToken do
  @moduledoc """
  mix compile ; mix app_count.soft_ledger_token
  """
  use Mix.Task
  @shortdoc "Fetch a New Soft Ledger Token"

  @spec run(any) :: no_return()
  def run(_) do
    Application.ensure_all_started(:external_service)
    Application.ensure_all_started(:httpoison)
    start_server()

    {:ok, o_auth_response} = AppCount.Adapters.SoftLedgerAdapter.fetch_token()
    IO.puts("Soft Ledger Token access_token ")
    IO.puts("")

    o_auth_response.access_token
    |> IO.puts()
  end

  def start_server do
    IO.puts("Starting SoftLedgerAdapter.Service")

    children = [{AppCount.Adapters.SoftLedgerAdapter.Service, []}]
    opts = [strategy: :one_for_one, name: AppCount.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
