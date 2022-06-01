defmodule AppCountWeb.Users.API.V1.AutoPayController do
  use AppCountWeb.Users, :controller
  alias AppCount.Accounts
  alias AppCount.Properties
  alias AppCountWeb.Helpers.ChangesetErrorHandler

  def create(conn, %{"autopay" => params}, dependencies \\ %{}) do
    params = params |> to_atoms()
    deps = Map.merge(default_deps(), dependencies)
    {:ok, raw_timestamp} = deps.utc_now_fn.("Etc/UTC")
    timestamp = DateTime.to_iso8601(raw_timestamp)

    params
    |> put_timestamp(timestamp)
    |> put_conn_info(conn)
    |> put_agreement_text(conn, deps.agreement_text_for_fn)
    |> deps.accounts.create_autopay()
    |> case do
      {:ok, _} ->
        json(conn, %{})

      {:error, changeset} ->
        errors = ChangesetErrorHandler.parse_errors(changeset)

        put_status(conn, 422)
        |> json(%{error: errors})
    end
  end

  def put_agreement_text(params, conn, agreement_text_for_fn) do
    agreement_text =
      AppCount.Core.ClientSchema.new("dasmen", conn.assigns.user.property)
      |> agreement_text_for_fn.()

    Map.put(params, :agreement_text, agreement_text)
  end

  def put_timestamp(params, timestamp) do
    Map.put(params, :agreement_accepted_at, timestamp)
  end

  def put_conn_info(params, conn) do
    params
    |> Map.merge(%{
      account_id: conn.assigns.user.account_id,
      tenant_id: conn.assigns.user.id,
      status: conn.assigns.user.payment_status,
      payer_ip_address: conn.assigns.formatted_ip_address
    })
  end

  def index(conn, _) do
    json(conn, Accounts.get_autopay_info(conn.assigns.user.account_id))
  end

  def update(conn, %{"id" => id, "autopay" => params}) do
    params = params |> to_atoms()

    params =
      Map.merge(params, %{
        tenant_id: conn.assigns.user.id
      })

    Accounts.update_autopay(id, params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "deactivate" => _}) do
    params = %{
      tenant_id: conn.assigns.user.id
    }

    Accounts.inactive_autopay(id, params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "activate" => _}) do
    params = %{
      tenant_id: conn.assigns.user.id
    }

    Accounts.activate_autopay(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    params = %{
      tenant_id: conn.assigns.user.id
    }

    Accounts.inactive_autopay(id, params)

    json(conn, %{})
  end

  defp default_deps() do
    %{
      accounts: Accounts,
      agreement_text_for_fn: &Properties.agreement_text_for/1,
      utc_now_fn: &DateTime.now/1
    }
  end
end
