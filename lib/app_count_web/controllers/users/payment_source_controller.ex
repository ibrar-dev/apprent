defmodule AppCountWeb.Users.PaymentSourceController do
  use AppCountWeb.Users, :controller
  alias AppCount.Accounts
  alias AppCount.Accounts.PaymentSource

  def index(conn, _params) do
    tenant_id = conn.assigns.user.id

    # Credit card tokenization credentials -- we'll use these client-side if the
    # tenant wants to add a new credit card to their profile.
    tokenization_credentials =
      tenant_id
      |> AppCount.Tenants.property_for()
      |> AppCount.Properties.Processors.public_details(:cc)

    payment_sources = Accounts.list_payment_sources(tenant_id)

    render(
      conn,
      "index.html",
      payment_sources: payment_sources,
      tokenization_credentials: tokenization_credentials
    )
  end

  def create(conn, %{"cc" => params}) do
    params
    |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)
    |> Map.merge(%{tenant_id: conn.assigns.user.id, account_id: conn.assigns.user.account_id})
    |> Accounts.create_payment_source()
    |> case do
      {:ok, ps} ->
        json(conn, %{id: ps.id})

      {:error, e} ->
        if is_binary(e) do
          put_status(conn, 422)
          |> json(%{error: "#{e}"})
        else
          {field, {reason, _}} = hd(e.errors)

          put_status(conn, 422)
          |> json(%{error: "#{field} #{reason}"})
        end
    end
  end

  def create(conn, %{"ba" => params}) do
    params
    |> Map.merge(%{"type" => "ba", "account_id" => conn.assigns.user.account_id})
    # handle possible missing last 4
    |> Map.merge(%{"last_4" => String.slice(params["account_number"] || "", -4..-1)})
    |> Accounts.create_payment_source()
    |> case do
      {:ok, ps} ->
        json(conn, %{id: ps.id})

      {:error, e} ->
        {field, {reason, _}} = hd(e.errors)

        put_status(conn, 422)
        |> json(%{error: "#{field} #{reason}"})
    end
  end

  def delete(conn, %{"id" => id}) do
    Accounts.delete_payment_source(id, false)

    conn
    |> put_flash(:success, "Payment Source deleted")
    |> redirect(to: Routes.user_ps_path(conn, :index))
  end

  def edit(conn, %{"id" => id}) do
    payment_source = accounts_boundary(conn).get_payment_source(conn.assigns.user.id, id)

    if is_nil(payment_source) do
      conn
      |> redirect(to: Routes.user_ps_path(conn, :index))
      |> halt()
    else
      # We found it!
      payment_source_cs =
        payment_source
        |> PaymentSource.changeset_for_update()

      render(
        conn,
        "edit.html",
        payment_source_changeset: payment_source_cs,
        payment_source: payment_source
      )
    end
  end

  def make_default(conn, %{"payment_source_id" => id}) do
    account = conn.assigns.user

    case accounts_boundary(conn).set_default_payment_source(account, id) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Default payment method set")
        |> redirect(to: Routes.user_ps_path(conn, :index))

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to set default payment method")
        |> redirect(to: Routes.user_ps_path(conn, :index))
    end
  end

  def update(conn, %{"id" => id, "payment_source" => params}) do
    case accounts_boundary(conn).update_payment_source(id, params) do
      {:ok, _payment_source} ->
        conn
        |> put_flash(:success, "Payment source updated")
        |> redirect(to: Routes.user_ps_path(conn, :index))

      {:error, changeset} ->
        payment_source = Accounts.get_payment_source(conn.assigns.user.id, id)

        render(
          conn,
          "edit.html",
          payment_source_changeset: changeset,
          payment_source: payment_source
        )
    end
  end
end
