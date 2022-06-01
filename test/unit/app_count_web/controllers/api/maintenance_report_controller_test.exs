defmodule AppCountWeb.Controllers.API.MaintenanceReportControllerTest do
  use AppCountWeb.ConnCase

  @stubbed_score 52.38

  defmodule ReportBoundaryParrot do
    @stubbed_score 52.38

    use TestParrot
    parrot(:report_boundary, :performance_report, @stubbed_score)
  end

  @tag subdomain: "administration"
  test "add_admin has no permissions", ~M[conn] do
    conn =
      conn
      |> assign(:report_boundary, ReportBoundaryParrot)

    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_admin()

    # admin = PropBuilder.get_requirement(builder, :admin)
    admin = AppCount.UserHelper.new_admin()
    property = PropBuilder.get_requirement(builder, :property)

    params = %{
      "property" => "#{property.id}",
      "type" => "performance_score"
    }

    conn = conn |> admin_request(admin)
    # When
    conn = get(conn, Routes.api_maintenance_report_path(conn, :index, params))

    assert json_response(conn, 200) == %{"current" => @stubbed_score}
  end
end
