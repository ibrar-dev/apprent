defmodule AppCountWeb.Management.ClientController do
  use AppCountWeb, :controller

  alias AppCount.Public
  alias AppCount.Public.Client
  alias AppCount.Public.User

  def index(conn, _params) do
    clients = Public.list_active_clients()

    render(conn, "index.html", clients: clients)
  end

  def new(conn, _params) do
    changeset = Public.change_client(%Client{users: [%User{}]})
    modules = AppCountAuth.ModuleRepo.list()

    render(conn, "new.html", changeset: changeset, modules: modules)
  end

  def create(conn, %{"client" => client_params}) do
    client_params = Map.put(client_params, "client_modules", Map.values(client_params["client_modules"]))
    changeset = Public.validate_client(%Client{users: [%User{}]}, client_params)

    if changeset.valid? do
      changeset
      |> Public.validated_client_to_map()
      |> run_new(conn)
    else
      changeset = Map.put(changeset, :action, :insert)
      modules = AppCountAuth.ModuleRepo.list()
      render(conn, "new.html", changeset: changeset, modules: modules)
    end
  end

  defp run_new(params, conn) do
    case Public.new_client_with_admin(params, create_schema: Map.get(conn.assigns, :create_schema, true)) do
      {:ok, _client} ->
        conn
        |> put_flash(:info, "Client created successfully.")
        |> redirect(to: Routes.client_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    client = Public.get_client!(id)
    render(conn, "show.html", client: client)
  end

  def edit(conn, %{"id" => id}) do
    modules = AppCountAuth.ModuleRepo.list()
    client = Public.get_client!(id)
    changeset = Public.edit_client(client)
    render(conn, "edit.html", client: client, changeset: changeset, modules: modules)
  end

  def update(conn, %{"id" => id, "client" => client_params}) do
    client_params = Map.put(client_params, "client_modules", Map.values(client_params["client_modules"]))
    client = Public.get_client!(id)

    case Public.update_client(client, client_params) do
      {:ok, client} ->
        conn
        |> put_flash(:info, "Client updated successfully.")
        |> redirect(to: Routes.client_path(conn, :show, client))

      {:error, %Ecto.Changeset{} = changeset} ->
        modules = AppCountAuth.ModuleRepo.list()
        render(conn, "edit.html", client: client, changeset: changeset, modules: modules)
    end
  end

  def delete(conn, %{"id" => id}) do
    client = Public.get_client!(id)
    {:ok, _client} = Public.deactivate_client(client)

    conn
    |> put_flash(:info, "Client Deactivated successfully.")
    |> redirect(to: Routes.client_path(conn, :index))
  end
end
