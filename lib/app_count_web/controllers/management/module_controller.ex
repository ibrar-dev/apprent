defmodule AppCountWeb.Management.ModuleController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    modules = AppCountAuth.ModuleRepo.list()
    render(conn, "index.html", modules: modules)
  end

  def new(conn, _params) do
    changeset = AppCountAuth.Module.changeset(%AppCountAuth.Module{}, %{name: ""})

    render(conn, "new.html", changeset: changeset, action: Routes.module_path(conn, :create))
  end

  def edit(conn, %{"id" => id}) do
    changeset =
      String.to_integer(id)
      |> AppCountAuth.ModuleRepo.get(prefix: "public")
      |> AppCountAuth.Module.changeset(%{})

    render(conn, "edit.html", changeset: changeset, action: Routes.module_path(conn, :update, id))
  end

  def create(conn, %{"module" => module_params}) do
    case AppCountAuth.ModuleRepo.insert(%{name: module_params["name"]}, prefix: "public") do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Module created successfully.")
        |> redirect(to: Routes.module_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "module" => module_params}) do
    String.to_integer(id)
    |> AppCountAuth.ModuleRepo.get(prefix: "public")
    |> AppCountAuth.ModuleRepo.update(module_params, prefix: "public")
    |> case do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Module updated successfully.")
        |> redirect(to: Routes.module_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html",
          changeset: changeset,
          action: Routes.module_path(conn, :update, id)
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    String.to_integer(id)
    |> AppCountAuth.ModuleRepo.delete(prefix: "public")

    conn
    |> put_flash(:info, "Module deleted successfully.")
    |> redirect(to: Routes.module_path(conn, :index))
  end
end
