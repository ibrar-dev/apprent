defmodule AppCount.Controllers.API.OccupantControllerTest do
  use AppCount.Case
  use AppCountWeb.ConnCase
  import AppCount.{Factory, LeaseHelper}
  alias AppCount.Properties.Occupant
  alias AppCount.Repo
  @moduletag :occupant_controller

  setup do
    now = AppCount.current_date()

    lease =
      insert_lease(%{
        start_date: Timex.shift(now, months: -6),
        end_date: Timex.shift(now, months: 6)
      })

    {:ok, [lease: lease, admin: admin_with_access([lease.unit.property.id])]}
  end

  test "create", %{conn: conn, admin: admin, lease: lease} do
    params = %{
      "occupant" => %{
        "first_name" => "Thomas",
        "last_name" => "Faraday",
        "email" => "tomfar@somewhere.com",
        "lease_id" => lease.id
      }
    }

    conn
    |> admin_request(admin)
    |> post("https://administration.example.com/api/occupants", params)
    |> json_response(200)

    assert Repo.get_by(
             Occupant,
             first_name: "Thomas",
             last_name: "Faraday",
             lease_id: lease.id,
             email: "tomfar@somewhere.com"
           )
  end

  test "update", %{conn: conn, admin: admin} do
    occupant = insert(:occupant)

    params = %{
      "occupant" => %{
        "first_name" => "Clancy"
      }
    }

    conn
    |> admin_request(admin)
    |> patch("https://administration.example.com/api/occupants/#{occupant.id}", params)
    |> json_response(200)

    assert Repo.get(Occupant, occupant.id).first_name == "Clancy"
  end

  test "delete", %{conn: conn, admin: admin} do
    occupant = insert(:occupant)

    conn
    |> admin_request(admin)
    |> delete("https://administration.example.com/api/occupants/#{occupant.id}")
    |> json_response(200)

    refute Repo.get(Occupant, occupant.id)
  end
end
