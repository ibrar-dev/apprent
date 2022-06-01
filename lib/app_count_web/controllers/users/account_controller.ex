defmodule AppCountWeb.Users.AccountController do
  use AppCountWeb.Users, :controller
  alias AppCount.Accounts

  def index(conn, _params) do
    render(
      conn,
      "index.html",
      user: conn.assigns.user,
      autopay: Accounts.get_autopay_info(conn.assigns.user.account_id),
      payment_sources: Accounts.list_payment_sources(conn.assigns.user.id)
    )
  end

  def update(conn, %{"account" => params}) do
    case Accounts.update_account(conn.assigns.user, params) do
      {:ok, _} ->
        conn
        |> json(%{})

      {:error, _} ->
        conn
        |> put_status(422)
        |> json(%{})
    end
  end

  def update(conn, %{"autopay" => params}) do
    new_params =
      params
      |> Map.put("tenant_id", conn.assigns.user.id)
      |> Map.put("account_id", conn.assigns.user.account_id)
      |> Map.put("payer_ip_address", conn.assigns.formatted_ip_address)
      |> Map.put("agreement_accepted_at", DateTime.utc_now())
      |> Morphix.atomorphiform!()

    if is_nil(Accounts.get_autopay_info(conn.assigns.user.account_id)) do
      case Accounts.create_autopay(new_params) do
        {:ok, _} ->
          conn
          |> json(%{})

        {:error, error} ->
          conn
          |> put_status(422)
          |> json(%{error: error})
      end
    else
      autopay = Accounts.get_autopay_info(conn.assigns.user.account_id)

      case Accounts.update_autopay(autopay.id, new_params) do
        {:ok, _} ->
          conn
          |> json(%{})

        {:error, error} ->
          conn
          |> put_status(422)
          |> json(%{error: error})
      end
    end
  end

  def update(conn, %{"profile" => params}) do
    new_params =
      Map.merge(Map.put(params, "account_id", conn.assigns.user.account_id), %{
        "active" => params["autopay"]
      })

    autopay = Accounts.get_autopay_info(conn.assigns.user.account_id)

    case Accounts.update_account(conn.assigns.user, params) do
      {:ok, _} ->
        if !is_nil(autopay), do: Accounts.update_autopay(autopay.id, new_params)

        conn
        |> put_flash(:success, "Profile Updated")
        |> redirect(to: "/profile")

      {:error, _} ->
        conn
        |> put_flash(:error, "Could not update profile")
        |> redirect(to: "/profile")
    end
  end
end
