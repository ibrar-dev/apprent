defmodule AppCountWeb.Controllers.API.TenantDocumentControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Properties.Document
  @moduletag :tenant_document_controller

  setup do
    property = insert(:property)
    {:ok, admin: admin_with_access([property.id]), tenant: insert(:tenant)}
  end

  test "index", %{conn: conn, admin: admin, tenant: tenant} do
    doc = insert(:tenant_document, tenant: tenant)

    resp =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/documents?tenant_id=#{tenant.id}")
      |> json_response(200)

    assert length(resp) == 1
    assert hd(resp)["name"] == doc.name
  end

  test "create", %{conn: conn, admin: admin, tenant: tenant} do
    data = File.read!(Path.expand("../../../resources/Sample1.pdf", __DIR__))
    uuid = AppCount.UploadServer.initialize_upload(1, "Sample1.pdf", "application/pdf")
    AppCount.UploadServer.push_piece(uuid, data, 1)

    params = %{
      "document" => %{
        "document" => %{
          "uuid" => uuid
        },
        "name" => "Doc Name",
        "tenant_id" => tenant.id,
        "type" => "Doc Type",
        "visible" => true
      }
    }

    conn
    |> admin_request(admin)
    |> post("https://administration.example.com/api/documents", params)
    |> json_response(200)

    assert Repo.get_by(Document, tenant_id: tenant.id, name: "Doc Name", type: "Doc Type")
  end

  test "update", %{conn: conn, admin: admin, tenant: tenant} do
    doc = insert(:tenant_document, tenant: tenant)

    new_params = %{
      "document" => %{
        "name" => "Really Cool Doc Name"
      }
    }

    conn
    |> admin_request(admin)
    |> patch("https://administration.example.com/api/documents/#{doc.id}", new_params)
    |> json_response(200)

    assert Repo.get(Document, doc.id).name == "Really Cool Doc Name"
  end

  test "delete", %{conn: conn, tenant: tenant, admin: admin} do
    doc = insert(:tenant_document, tenant: tenant)

    conn
    |> admin_request(admin)
    |> delete("https://administration.example.com/api/documents/#{doc.id}")
    |> json_response(200)

    refute Repo.get(Document, doc.id)
  end
end
