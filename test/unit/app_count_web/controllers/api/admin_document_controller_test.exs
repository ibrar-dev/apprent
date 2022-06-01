defmodule AppCountWeb.Controllers.API.AdminDocumentControllerTest do
  use AppCountWeb.ConnCase
  @moduletag :admin_document_controller

  setup do
    property = insert(:property)
    {:ok, [property: property, admin: admin_with_access([property.id])]}
  end

  test "create/update/delete", %{conn: conn, admin: admin, property: property} do
    data = File.read!(Path.expand("../../../resources/sample.png", __DIR__))
    uuid = AppCount.UploadServer.initialize_upload(1, "sample.png", "image/png")
    AppCount.UploadServer.push_piece(uuid, data, 1)

    params = %{
      "params" => %{
        "name" => "Doc Name",
        "type" => "Doc Type",
        "property_ids" => [property.id],
        "document" => %{
          "uuid" => uuid
        }
      }
    }

    conn
    |> admin_request(admin)
    |> post("https://administration.example.com/api/admin_documents", params)
    |> json_response(200)

    docs = AppCount.Properties.find_documents([property.id])
    assert length(docs) == 1
    doc = hd(docs)
    assert doc.type == "Doc Type"
    assert doc.name == "Doc Name"
    assert doc.creator == admin.name

    conn
    |> admin_request(admin)
    |> patch(
      "https://administration.example.com/api/admin_documents/#{doc.id}",
      %{
        "params" => %{
          "name" => "New Name"
        }
      }
    )
    |> json_response(200)

    docs = AppCount.Properties.find_documents([property.id])
    assert length(docs) == 1
    doc = hd(docs)
    assert doc.type == "Doc Type"
    assert doc.name == "New Name"

    conn
    |> admin_request(admin)
    |> delete("https://administration.example.com/api/admin_documents/#{doc.id}")
    |> json_response(200)

    assert AppCount.Properties.find_documents([property.id]) == []
  end
end
