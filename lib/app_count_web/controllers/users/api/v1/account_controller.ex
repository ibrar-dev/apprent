defmodule AppCountWeb.Users.API.V1.AccountController do
  use AppCountWeb.Users, :controller
  alias AppCount.Accounts
  alias AppCount.Tenants
  alias AppCountWeb.Helpers.ChangesetErrorHandler

  def index(conn, _params) do
    user_info =
      Map.merge(
        Accounts.unit_info(conn.assigns.user.id),
        %{user: Map.from_struct(conn.assigns.user)}
      )

    json(conn, user_info)
  end

  def update(conn, %{"account" => params}) do
    result = Accounts.update_account(conn.assigns.user, params)

    case result do
      {:ok, tenant} ->
        json(conn, %{user: tenant})

      {:error, changeset} ->
        errors = ChangesetErrorHandler.parse_errors(changeset)

        conn
        |> put_status(400)
        |> json(%{error: errors})
    end
  end

  def update(conn, %{"profile" => params}) do
    result = Accounts.update_account(conn.assigns.user, params)

    case result do
      {:ok, tenant} ->
        json(conn, %{user: tenant})

      {:error, changeset} ->
        errors = ChangesetErrorHandler.parse_errors(changeset)

        conn
        |> put_status(400)
        |> json(%{error: errors})
    end
  end

  def create(conn, %{"verify" => params}) do
    case Accounts.verify_tenant(params) do
      {:ok, _tenant_id} ->
        json(conn, %{status: "account created. Please check your emails"})

      {:success, message} ->
        json(conn, %{status: message})

      _ ->
        conn
        |> put_status(400)
        |> json(%{error: "incorrect credentials"})
    end
  end

  def create(conn, %{"tenant_id" => tenant_id, "email" => email}) do
    case Tenants.update_tenant(tenant_id, %{email: email}) do
      {:ok, _} ->
        case Accounts.create_tenant_account(tenant_id) do
          {:ok, _} ->
            json(conn, %{})

          {:error, %{errors: errors}} ->
            message =
              Enum.reduce(errors, "", fn e, acc -> normalize_message(e) <> acc end)
              |> String.slice(0..-2)

            conn
            |> put_status(400)
            |> json(message)

          {:error, message} ->
            conn
            |> put_status(400)
            |> json(message)
        end

      {:error, message} ->
        conn
        |> put_status(400)
        |> json(message)
    end
  end

  defp normalize_message({f, {e, _}}) do
    "#{f} #{e},"
    |> String.replace(~r/_id/, "")
    |> String.replace(~r/_/, " ")
    |> String.capitalize()
  end
end
