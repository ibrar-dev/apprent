defmodule AppCountWeb.Controllers.API.TenantSafeControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Repo
  alias AppCount.Leases.Screening

  @moduletag :tenant_safe_controller
  @partial_xml File.read!(Path.expand("../../../resources/tenant_safe_partial.xml", __DIR__))
  @ready_xml File.read!(Path.expand("../../../resources/tenant_safe_ready.xml", __DIR__))
  @id_placeholder "--id_here--"

  setup do
    {:ok, screening: insert(:screening), person: insert(:property_person)}
  end

  test "update partial", %{conn: conn, screening: screening} do
    xml =
      @partial_xml
      |> String.replace(@id_placeholder, "#{screening.id}")

    conn
    |> post("http://administration.example.com/tenant_safe", %{"Status" => xml})
    |> json_response(200)

    updated = Repo.get(Screening, screening.id)
    assert length(updated.xml_data) == 1
    assert updated.url
    assert updated.status == "partial"
  end

  test "update ready", %{conn: conn, screening: screening} do
    xml =
      @ready_xml
      |> String.replace(@id_placeholder, "#{screening.id}")

    conn
    |> post("http://administration.example.com/tenant_safe", %{"Status" => xml})
    |> json_response(200)

    updated = Repo.get(Screening, screening.id)
    refute updated.gateway_xml
    assert updated.url
    assert updated.status == "ready"
  end
end
