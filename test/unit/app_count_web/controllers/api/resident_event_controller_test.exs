defmodule AppCountWeb.Controllers.API.ResidentEventControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Properties.ResidentEvent
  @moduletag :resident_event_controller

  setup do
    property = insert(:property)
    {:ok, admin: admin_with_access([property.id]), property: property}
  end

  test "index", %{conn: conn, admin: admin, property: property} do
    event = insert(:resident_event, property: property, name: "Special Event Name!")

    resp =
      conn
      |> admin_request(admin)
      |> get("http://administration.example.com/api/resident_events?property_id=#{property.id}")
      |> json_response(200)

    assert length(resp) == 1
    assert hd(resp)["name"] == event.name
  end

  # code:  assert length(resp) == 1
  #    left:  2
  #    right: 1
  #    stacktrace:
  #      test/app_count_web/controllers/api/resident_event_controller_test.exs:49: (test)
  test "upcoming index", %{conn: conn, admin: admin, property: property} do
    yesterday =
      AppCount.current_date()
      |> Timex.shift(days: -1)

    tomorrow =
      AppCount.current_date()
      |> Timex.shift(days: 1)

    insert(:resident_event, property: property, name: "past event name", date: yesterday)

    event =
      insert(:resident_event, property: property, name: "upcoming event name", date: tomorrow)

    resp =
      conn
      |> admin_request(admin)
      |> get(
        "http://administration.example.com/api/resident_events?property_id=#{property.id}&upcoming=true"
      )
      |> json_response(200)

    assert length(resp) == 1
    assert hd(resp)["name"] == event.name
  end

  test "show", %{conn: conn, admin: admin, property: property} do
    event = insert(:resident_event, property: property, name: "Weird Event")

    resp =
      conn
      |> admin_request(admin)
      |> get("http://administration.example.com/api/resident_events/#{event.id}")
      |> json_response(200)

    assert resp["name"] == event.name
  end

  test "create", %{conn: conn, admin: admin, property: property} do
    data = File.read!(Path.expand("../../../resources/sample.png", __DIR__))
    uuid = AppCount.UploadServer.initialize_upload(1, "sample.png", "image/png")
    AppCount.UploadServer.push_piece(uuid, data, 1)

    params = %{
      "resident_event" => %{
        "date" => "2019-05-15",
        "end_time" => "630",
        "image" => %{
          "uuid" => uuid
        },
        "info" => "Whenever",
        "location" => "Wherever",
        "name" => "Whatever",
        "property_id" => property.id,
        "start_time" => "540",
        "notify" => "true"
      }
    }

    conn
    |> admin_request(admin)
    |> post("http://administration.example.com/api/resident_events", params)
    |> json_response(200)

    assert Repo.get_by(ResidentEvent, property_id: property.id, info: "Whenever")
  end

  test "update", %{conn: conn, admin: admin, property: property} do
    event = insert(:resident_event, property: property, name: "Weird Event")

    params = %{
      "resident_event" => %{
        "name" => "New Name"
      }
    }

    conn
    |> admin_request(admin)
    |> patch("http://administration.example.com/api/resident_events/#{event.id}", params)
    |> json_response(200)

    assert Repo.get(ResidentEvent, event.id).name == "New Name"
  end

  test "delete", %{conn: conn, admin: admin, property: property} do
    event = insert(:resident_event, property: property, name: "Mistaken Event")

    conn
    |> admin_request(admin)
    |> delete("http://administration.example.com/api/resident_events/#{event.id}")
    |> json_response(200)

    refute Repo.get(ResidentEvent, event.id)
  end
end
