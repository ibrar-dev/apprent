defmodule AppCountWeb.API.FinanceAccountController do
  use AppCountWeb, :controller
  alias AppCountWeb.Helpers.ChangesetErrorHandler

  def index(conn, _params) do
    finance_boundary(conn).list_accounts()
    |> case do
      {:ok, accounts} ->
        conn
        |> json(%{data: accounts})

      # There aren't any cases yet where we're likely to fail
      {:error, _} ->
        conn
        |> put_status(400)
        |> json(%{errors: ["Something went really screwy"]})
    end
  end

  def create(
        conn,
        %{} = params
      ) do
    finance_boundary(conn).create_account(params)
    |> case do
      {:ok, %AppCount.Finance.Account{} = account} ->
        conn
        |> put_status(201)
        |> json(%{data: account})

      # There aren't any cases yet where we're likely to fail
      {:error, changeset} ->
        error = ChangesetErrorHandler.parse_errors(changeset)

        conn
        |> put_status(400)
        |> json(%{error: error})
    end
  end

  def show(conn, %{"id" => id}) do
    finance_boundary(conn).get_account(id)
    |> case do
      {:ok, account} ->
        conn
        |> json(%{data: account})

      {:error, message} ->
        conn
        |> put_status(404)
        |> json(%{errors: [message]})
    end
  end
end
