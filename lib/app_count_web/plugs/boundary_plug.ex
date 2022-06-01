defmodule AppCountWeb.BoundaryPlug do
  import Plug.Conn

  @deps %{
    admins: AppCount.Admins,
    maintenance: AppCount.Maintenance,
    report_boundary: AppCount.Maintenance.ReportBoundary,
    rewards_boundary: AppCount.Rewards.RewardsBoundary,
    tenant_boundary: AppCount.Tenants,
    bounce_repo_boundary: AppCount.Messaging.BounceRepo,
    charge_code_repo_boundary: AppCount.Ledgers.ChargeCodeRepo,
    properties_boundary: AppCount.Properties,
    accounts_boundary: AppCount.Accounts,
    payment_boundary: AppCount.Core.PaymentBoundary,
    accounting_boundary: AppCount.Accounting,
    vendor_order_boundary: AppCount.Vendors,
    finance_boundary: AppCount.Finance.FinanceBoundary,
    tech_recommend_boundary: AppCount.Maintenance.TechRecommendBoundary
  }

  def init(_opts) do
  end

  def call(conn, _opts) do
    # NOTE: also add a help function to module: AppCountWeb.BoundaryHelpers
    conn
    |> load_boundary(:admins, @deps.admins)
    |> load_boundary(:maintenance, @deps.maintenance)
    |> load_boundary(:report_boundary, @deps.report_boundary)
    |> load_boundary(:rewards_boundary, @deps.rewards_boundary)
    |> load_boundary(:tenant_boundary, @deps.tenant_boundary)
    |> load_boundary(:bounce_repo_boundary, @deps.bounce_repo_boundary)
    |> load_boundary(:properties_boundary, @deps.properties_boundary)
    |> load_boundary(:accounts_boundary, @deps.accounts_boundary)
    |> load_boundary(:payment_boundary, @deps.payment_boundary)
    |> load_boundary(:charge_code_repo_boundary, @deps.charge_code_repo_boundary)
    |> load_boundary(:accounting_boundary, @deps.accounting_boundary)
    |> load_boundary(:vendor_order_boundary, @deps.vendor_order_boundary)
    |> load_boundary(:finance_boundary, @deps.finance_boundary)
    |> load_boundary(:tech_recommend_boundary, @deps.tech_recommend_boundary)
  end

  defp load_boundary(conn, boundary_name, module) do
    if conn.assigns[boundary_name] do
      conn
    else
      assign(conn, boundary_name, module)
    end
  end

  # This module loads boundaries into the conn in the following order of precedence:
  # 1.  If the conn already has defined the boundary in question, use that one
  #     (often a TestParrot)
  # 2.  If our environment config specifies a boundary (given the boundary name),
  #     use that -- in config/test.exs, for example
  # 3.  Otherwise, use the default boundary for the boundary name, typically
  #     defined in @deps, passed in through call/2
  #
  # In all cases, takes a conn (plus some stuff) and returns a modified conn
  #
  # defp load_boundary(conn, boundary_name, module) do
  #   if conn.assigns[boundary_name] do
  #     conn
  #   else
  #     fake_boundaries = Application.get_env(:app_count, :boundary, %{})
  #     fake_boundary = Map.get(fake_boundaries, boundary_name, false)
  #     assign(conn, boundary_name, fake_boundary || module)
  #   end
  # end
end
