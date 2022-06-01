defmodule AppCountWeb.API.ReportTemplateController do
  use AppCountWeb, :controller
  alias AppCount.Accounting

  authorize(["Accountant"])

  def index(conn, _params) do
    json(conn, Accounting.list_report_templates())
  end

  def create(conn, %{"report_template" => params}) do
    Accounting.create_report_template(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "report_template" => params}) do
    Accounting.update_report_template(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Accounting.delete_report_template(id)
    json(conn, %{})
  end
end
