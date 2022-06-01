defmodule AppCountWeb.BoundaryHelpers do
  # NOTE: each of these must have a call to load_boundary() into AppCountWeb.BoundaryPlug
  def maintenance(conn), do: conn.assigns.maintenance
  def report_boundary(conn), do: conn.assigns.report_boundary
  def admins(conn), do: conn.assigns.admins
  def rewards_boundary(conn), do: conn.assigns.rewards_boundary
  def tenant_boundary(conn), do: conn.assigns.tenant_boundary
  def bounce_repo_boundary(conn), do: conn.assigns.bounce_repo_boundary
  def properties_boundary(conn), do: conn.assigns.properties_boundary
  def accounts_boundary(conn), do: conn.assigns.accounts_boundary
  def payment_boundary(conn), do: conn.assigns.payment_boundary
  def charge_code_repo_boundary(conn), do: conn.assigns.charge_code_repo_boundary
  def accounting_boundary(conn), do: conn.assigns.accounting_boundary
  def vendor_order_boundary(conn), do: conn.assigns.vendor_order_boundary
  def finance_boundary(conn), do: conn.assigns.finance_boundary
  def tech_recommend_boundary(conn), do: conn.assigns.tech_recommend_boundary

  def to_atoms(params) do
    {:ok, params} = Morphix.atomorphiform(params)
    params
  end
end
