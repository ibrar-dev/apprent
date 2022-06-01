defmodule AppCountWeb.Management.ActionController do
  use AppCountWeb, :controller

  def index(conn, %{"module_id" => module_id}) do
    actions = AppCountAuth.ActionRepo.list(module_id)
    modules = AppCountAuth.ModuleRepo.list()
    render(conn, "index.html", actions: actions, module_id: module_id, modules: modules)
  end

  def index(conn, _params) do
    actions = AppCountAuth.ActionRepo.list()
    modules = AppCountAuth.ModuleRepo.list()
    render(conn, "index.html", actions: actions, module_id: 0, modules: modules)
  end

  def new(conn, _params) do
    changeset =
      AppCountAuth.Action.changeset(
        %AppCountAuth.Action{},
        %{permission_type: "read-write"}
      )

    modules = AppCountAuth.ModuleRepo.list()

    render(conn, "new.html",
      changeset: changeset,
      modules: modules,
      action: Routes.action_path(conn, :create)
    )
  end

  def edit(conn, %{"id" => id}) do
    changeset =
      String.to_integer(id)
      |> AppCountAuth.ActionRepo.get(prefix: "public")
      |> AppCountAuth.Action.changeset(%{})

    modules = AppCountAuth.ModuleRepo.list()

    render(conn, "edit.html",
      changeset: changeset,
      modules: modules,
      action: Routes.action_path(conn, :update, id)
    )
  end

  def create(conn, %{"action" => action_params}) do
    case AppCountAuth.ActionRepo.insert(action_params, prefix: "public") do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Action created successfully.")
        |> redirect(to: Routes.action_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        modules = AppCountAuth.ModuleRepo.list()

        render(conn, "new.html",
          changeset: changeset,
          modules: modules,
          action: Routes.action_path(conn, :create)
        )
    end
  end

  def update(conn, %{"id" => id, "action" => action_params}) do
    String.to_integer(id)
    |> AppCountAuth.ActionRepo.get(prefix: "public")
    |> AppCountAuth.ActionRepo.update(action_params, prefix: "public")
    |> case do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Action updated successfully.")
        |> redirect(to: Routes.action_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, action: Routes.action_path(conn, :update))
    end
  end

  def delete(conn, %{"id" => id}) do
    String.to_integer(id)
    |> AppCountAuth.ActionRepo.delete(prefix: "public")

    conn
    |> put_flash(:info, "Action deleted successfully.")
    |> redirect(to: Routes.action_path(conn, :index))
  end
end
