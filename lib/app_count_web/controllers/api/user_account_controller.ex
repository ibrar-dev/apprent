defmodule AppCountWeb.API.UserAccountController do
  use AppCountWeb, :controller
  alias AppCount.Accounts

  authorize(["Admin", "Agent", "Accountant"])

  def create(conn, %{"tenant_id" => tenant_id}) do
    case Accounts.create_tenant_account(tenant_id) do
      {:ok, _} ->
        json(conn, %{})

      {:error, %{errors: errors}} ->
        message =
          Enum.reduce(errors, "", fn e, acc -> normalize_message(e) <> acc end)
          |> String.slice(0..-2)

        conn
        |> put_status(501)
        |> json(message)

      {:error, message} ->
        conn
        |> put_status(501)
        |> json(message)
    end
  end

  def create(conn, %{"reset_password" => email}) do
    Accounts.reset_password_request(email)
    json(conn, %{})
  end

  def show(conn, %{"id" => tenant_id}) do
    json(conn, %{account: Accounts.get_account(tenant_id)})
  end

  def update(conn, %{"id" => id, "account" => %{"password" => password}}) do
    admin = conn.assigns.admin

    Accounts.update_account(id, %{"password" => password, "admin_id" => admin.id})

    json(conn, %{})
  end

  def update(conn, %{"id" => id, "account" => params}) do
    Accounts.update_account(id, params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "send_welcome" => _}) do
    Accounts.send_welcome_email(id)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Accounts.delete_account(id)
    json(conn, %{})
  end

  defp normalize_message({f, {e, _}}) do
    "#{f} #{e},"
    |> String.replace(~r/_id/, "")
    |> String.replace(~r/_/, " ")
    |> String.capitalize()
  end
end
