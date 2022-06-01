defmodule Mix.Tasks.MultiTenantSetup do
  @moduledoc """
    Intended for use in tests to set up multiple client schemas
  """
  use Mix.Task
  import Ecto.Query

  def run(_) do
    Logger.configure(level: :warn)

    Ecto.Migrator.with_repo(
      AppCount.Repo,
      fn repo ->
        %{name: "Dasmen Residential", client_schema: "dasmen", status: "active"}
        |> create_new_tenant(repo)

        %{name: "Test Full", client_schema: "test", status: "active"}
        |> create_new_tenant(repo)

        %{name: "Maintenance Test", client_schema: "maintenance", status: "active"}
        |> create_new_tenant(repo)
      end
    )
  end

  def create_new_tenant(client, repo) do
    if !repo.exists?(from(c in AppCount.Public.Client, where: c.name == ^client.name)) do
      client
      |> AppCount.Public.create_client(create_schema: client.name != "dasmen")
    end
  end
end
