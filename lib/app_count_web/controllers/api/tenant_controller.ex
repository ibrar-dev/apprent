defmodule AppCountWeb.API.TenantController do
  use AppCountWeb, :controller
  alias AppCount.Tenants
  authorize(["Admin", "Agent", "Accountant"], index: ["Tech", "Admin", "Agent"])

  def index(conn, %{"property_id" => property_id, "type" => type}) do
    json(conn, tenant_boundary(conn).get_residents_by_type(conn.assigns.admin, property_id, type))
  end

  def index(conn, %{"min" => _}) do
    json(conn, tenant_boundary(conn).list_tenants_min(conn.assigns.admin))
  end

  def index(conn, %{"search" => name, "property_id" => property_id}) do
    json(conn, tenant_boundary(conn).tenant_search(conn.assigns.admin, name, property_id))
  end

  def index(conn, %{"with_bal" => _, "property_id" => property_id}) do
    json(conn, tenant_boundary(conn).list_tenants_balance(property_id))
  end

  def index(conn, %{"property_id" => property_id}) do
    json(conn, tenant_boundary(conn).list_tenants(conn.assigns.admin, property_id))
  end

  def index(conn, %{"search" => term}) do
    json(conn, tenant_boundary(conn).navbar_search(conn.assigns.admin, term))
  end

  def index(conn, _) do
    safe_json(conn, tenant_boundary(conn).list_tenants(conn.assigns.admin))
  end

  def create(conn, %{"tenant" => params, "lease_id" => lease_id}) do
    params
    |> Map.put("admin", conn.assigns.admin)
    |> tenant_boundary(conn).create_tenant(lease_id: lease_id)
    |> handle_error(conn)
  end

  def create(conn, %{"tenant" => params, "create_new" => _}) do
    Map.put(params, "admin", conn.assigns.admin.name)
    |> tenant_boundary(conn).create_new_tenant()
    |> handle_error(conn)
  end

  def create(conn, %{"tenant" => params}) do
    Map.put(params, "admin", conn.assigns.admin.name)
    |> tenant_boundary(conn).create_tenant()
    |> handle_error(conn)
  end

  def show(conn, %{"id" => tenant_id, "lease_id" => lease_id, "export" => _}) do
    %{unit_info: unit_info, ledger: ledger, tenant: tenant_data} =
      Tenants.download_ledger(tenant_id, lease_id)

    {:ok, data} =
      Phoenix.View.render_to_string(
        AppCountWeb.Exports.Residents.ResidentLedgerView,
        "index.html",
        %{unit_info: unit_info, ledger: ledger, tenant: tenant_data}
      )
      |> PdfGenerator.generate_binary()

    date = AppCount.current_date()

    send_download(
      conn,
      {:binary, data},
      content_type: "application/pdf",
      filename: "ResidentLedgerExport#{date}.pdf"
    )
  end

  def show(conn, %{"id" => id}) do
    data = tenant_boundary(conn).get_tenant(conn.assigns.admin, id)
    json(conn, data)
  end

  def update(conn, %{"id" => id, "sync" => _}) do
    case tenant_boundary(conn).sync_external_id(id) do
      {:ok, %{external_id: id}} -> json(conn, %{success: id})
      {:error, error} -> json(conn, %{error: error})
    end
  end

  def update(conn, %{"id" => id, "tenant" => params}) do
    tenant_boundary(conn).update_tenant(id, params)
    json(conn, %{})
  end

  def clear_bounces(conn, %{"tenant_id" => id}) do
    tenant_boundary(conn).clear_bounces(id)

    json(conn, %{})
  end
end
