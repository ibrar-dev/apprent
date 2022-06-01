defmodule AppCountWeb.Users.API.V1.PaymentSourceController do
  use AppCountWeb.Users, :controller
  alias AppCount.Accounts
  alias AppCountWeb.Helpers.ChangesetErrorHandler
  require Logger

  def index(conn, _) do
    json(conn, Accounts.list_payment_sources(conn.assigns.user.id))
  end

  def tokenization_credentials(conn, _) do
    # Credit card tokenization credentials -- we'll use these client-side if the
    # tenant wants to add a new credit card to their profile.
    tokenization_credentials =
      conn.assigns.user.id
      |> AppCount.Tenants.property_for()
      |> AppCount.Properties.Processors.public_details(:cc)

    json(conn, tokenization_credentials)
  end

  # Credit Card - Raw PAN Data
  def create(conn, %{"cc" => _params}) do
    conn
    |> put_status(422)
    |> json(%{error: "Please download the updated version of the mobile app, then try again."})
  end

  # Credit Card - Tokenized
  def create(conn, %{"cc_tokenized" => params}) when is_map_key(params, "token_value") do
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

  # Bank Account - Raw Account Data
  def create(conn, %{"ba" => params}) do
    last_4 = params["last_4"] || String.slice(params["number"] || "", -4..-1)

    # We'll be able to remove this once we get the mobile app version deployed
    account_subtype = params["subtype"] || "checking"

    params
    |> Map.merge(%{"type" => "ba", "account_id" => conn.assigns.user.account_id})
    |> Map.merge(%{"subtype" => account_subtype})
    |> Map.merge(%{"last_4" => last_4})
    |> Accounts.create_payment_source()
    |> case do
      {:ok, ps} ->
        json(conn, %{id: ps.id})

      {_, _} ->
        conn
        |> put_status(422)
        |> json(%{error: "There was an error saving your bank account."})
    end
  end

  def update(conn, %{"id" => id, "payment_source" => params}) do
    case Accounts.update_payment_source(id, params) do
      {:ok, payment_source} ->
        conn
        |> json(%{data: payment_source})

      {:error, changeset} ->
        errors = ChangesetErrorHandler.parse_errors(changeset)

        conn
        |> put_status(400)
        |> json(%{error: errors})
    end
  end

  def make_default(conn, %{"payment_source_id" => id}) do
    account_id = conn.assigns.user.account_id

    result = Accounts.set_default_payment_source(%{account_id: account_id}, id)

    case result do
      {:ok, _} ->
        json(conn, %{payment_source_id: id})

      {:error, changeset} ->
        errors = ChangesetErrorHandler.parse_errors(changeset)

        conn
        |> put_status(400)
        |> json(%{error: errors})
    end
  end

  def delete(conn, %{"id" => id}) do
    Accounts.delete_payment_source(id, false)
    json(conn, %{})
  end
end
