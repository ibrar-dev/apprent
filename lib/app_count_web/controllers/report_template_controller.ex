defmodule AppCountWeb.ReportTemplateController do
  use AppCountWeb, :controller

  authorize(["Accountant"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Set Up Reports"})
  end
end
