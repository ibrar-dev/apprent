defmodule AppCountWeb.Requests.API.TechTest do
  use AppCountWeb.ConnCase
  use AppCount.DataCase
  alias AppCount.Maintenance
  alias AppCount.Core.ClientSchema

  setup do
    property = insert(:property)
    tech = insert(:job, property: property).tech
    skills = [insert(:skill, tech: tech), insert(:skill, tech: tech)]

    {:ok,
     tech: tech,
     property: property,
     skills: skills,
     admin: %{property_ids: [property.id], roles: ["Tech"]}}
  end

  test "GET api/techs?min=true", ~M[admin, conn, tech, property] do
    list_of_techs = [
      %{"id" => tech.id, "name" => tech.name, "property_ids" => [property.id]}
    ]

    conn =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/techs?min=true")

    assert json_response(conn, 200) == list_of_techs
  end

  test "GET api/techs?tech=true as Super Admin", ~M[admin, conn, tech, property, skills] do
    list_of_techs = [
      %{
        "id" => tech.id,
        "name" => tech.name,
        "property_ids" => [property.id],
        "active" => true,
        "can_edit" => false,
        "category_ids" => Enum.map(skills, & &1.category_id),
        "description" => "",
        "email" => "tech@yahoo.com",
        "image" => nil,
        "lat" => nil,
        "lng" => nil,
        "month_stats" => nil,
        "pass_code" => tech.pass_code,
        "phone_number" => tech.phone_number,
        "presence" => false,
        "require_image" => false,
        "stats" => nil,
        "type" => "Tech"
      }
    ]

    conn =
      conn
      |> admin_request(%{admin | roles: ["Super Admin"]})
      |> get("https://administration.example.com/api/techs?tech=true")

    assert json_response(conn, 200) == list_of_techs
  end

  test "GET api/techs?tech=true as Tech admin", ~M[admin, conn, tech, property, skills] do
    list_of_techs = [
      %{
        "id" => tech.id,
        "name" => tech.name,
        "property_ids" => [property.id],
        "active" => true,
        "can_edit" => false,
        "category_ids" => Enum.map(skills, & &1.category_id),
        "description" => "",
        "email" => "tech@yahoo.com",
        "image" => nil,
        "lat" => nil,
        "lng" => nil,
        "month_stats" => nil,
        "pass_code" => tech.pass_code,
        "phone_number" => tech.phone_number,
        "presence" => false,
        "require_image" => false,
        "stats" => nil,
        "type" => "Tech"
      }
    ]

    conn =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/techs?tech=true")

    assert json_response(conn, 200) == list_of_techs
  end

  test "GET api/techs?loc=true", ~M[admin, conn, tech] do
    # set some coordinates for the tech
    coords = %{lat: 150, lng: 140}
    Maintenance.set_tech_coords(%ClientSchema{name: "dasmen", attrs: tech.id}, coords)

    # log tech presence
    AppCountWeb.TechPresence.track(
      self(),
      "tech_admin",
      "dasmen-#{tech.id}",
      %{online_at: inspect(System.system_time(:second))}
    )

    list_of_techs = [
      %{
        "id" => tech.id,
        "name" => tech.name,
        "image" => nil,
        "lat" => 150,
        "lng" => 140,
        "presence" => true
      }
    ]

    conn =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/techs?loc=true")

    assert json_response(conn, 200) == list_of_techs
  end

  test "GET api/techs?assign=true", ~M[admin, conn, tech, property, skills] do
    order = insert(:order, status: "assigned")
    insert(:assignment, tech: tech, order: order, status: "on_hold")
    insert(:assignment, tech: tech, order: order, status: "on_hold")

    list_of_techs = [
      %{
        "id" => tech.id,
        "name" => tech.name,
        "assignments" => 2,
        "category_ids" => Enum.map(skills, & &1.category_id),
        "email" => "tech@yahoo.com",
        "month_stats" => nil,
        "phone_number" => tech.phone_number,
        "property_ids" => [property.id],
        "stats" => nil,
        "type" => tech.type,
        "image" => nil
      }
    ]

    conn =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/techs?assign=true")

    assert json_response(conn, 200) == list_of_techs
  end

  test "GET api/techs", ~M[admin, conn, tech, property, skills] do
    order = insert(:order, status: "assigned")
    assignment1 = insert(:assignment, tech: tech, order: order, status: "on_hold")
    assignment2 = insert(:assignment, tech: tech, order: order, status: "in_progress")

    list_of_techs = [
      %{
        "id" => tech.id,
        "name" => tech.name,
        "assignments" => [
          %{
            "completed_at" => nil,
            "id" => assignment1.id,
            "inserted_at" => String.replace("#{assignment1.inserted_at}", " ", "T"),
            "order_id" => order.id,
            "rating" => nil,
            "status" => "on_hold"
          },
          %{
            "completed_at" => nil,
            "id" => assignment2.id,
            "inserted_at" => String.replace("#{assignment2.inserted_at}", " ", "T"),
            "order_id" => order.id,
            "rating" => nil,
            "status" => "in_progress"
          }
        ],
        "category_ids" => Enum.map(skills, & &1.category_id),
        "email" => "tech@yahoo.com",
        "month_stats" => nil,
        "phone_number" => tech.phone_number,
        "property_ids" => [property.id],
        "stats" => nil,
        "type" => tech.type,
        "active" => true,
        "can_edit" => false,
        "description" => "",
        "lat" => nil,
        "lng" => nil,
        "pass_code" => nil,
        "presence" => false,
        "require_image" => false,
        "image" => nil
      }
    ]

    conn =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/techs")

    assert json_response(conn, 200) == list_of_techs
  end

  test "GET api/techs/:id?detailed_info?=true", ~M[admin, conn, tech, skills] do
    order = insert(:order, status: "assigned")
    assignment1 = insert(:assignment, tech: tech, order: order, status: "on_hold")
    assignment2 = insert(:assignment, tech: tech, order: order, status: "in_progress")

    expected_order_params = %{
      "category" => order.category.name,
      "id" => order.id,
      "property" => "Test Property",
      "submitted" => String.replace("#{order.inserted_at}", " ", "T"),
      "tenant" => order.tenant.first_name <> " " <> order.tenant.last_name,
      "unit" => order.unit.number
    }

    expected = %{
      "active" => true,
      "assignments" => [
        %{
          "completed_at" => nil,
          "id" => assignment1.id,
          "inserted_at" => String.replace("#{assignment1.inserted_at}", " ", "T"),
          "order_id" => order.id,
          "rating" => nil,
          "status" => "on_hold",
          "confirmed_at" => nil,
          "order" => expected_order_params,
          "updated_at" => String.replace("#{assignment1.updated_at}", " ", "T")
        },
        %{
          "completed_at" => nil,
          "id" => assignment2.id,
          "inserted_at" => String.replace("#{assignment2.inserted_at}", " ", "T"),
          "order_id" => order.id,
          "rating" => nil,
          "status" => "in_progress",
          "confirmed_at" => nil,
          "order" => expected_order_params,
          "updated_at" => String.replace("#{assignment2.updated_at}", " ", "T")
        }
      ],
      "can_edit" => false,
      "category_ids" => Enum.map(skills, & &1.category_id),
      "description" => "",
      "email" => "tech@yahoo.com",
      "id" => tech.id,
      "image" => nil,
      "name" => tech.name,
      "pass_code" => nil,
      "phone_number" => tech.phone_number,
      "stats" => nil,
      "toolbox" => [],
      "type" => tech.type
    }

    conn =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/techs/#{tech.id}?detailed_info=true")

    assert json_response(conn, 200) == expected
  end

  test "GET api/techs/:id?pastStats?=true", ~M[admin, conn, tech] do
    date_in_last_month =
      AppCount.current_time()
      |> Timex.beginning_of_month()
      |> Timex.shift(days: -2)

    last_month_assignment =
      insert(:assignment,
        tech: tech,
        rating: 5,
        status: "completed",
        completed_at: date_in_last_month
      )

    expected =
      [
        %{
          "callback" => [],
          "complete" => [],
          "date" => Timex.beginning_of_month(AppCount.current_time()),
          "id" => tech.id,
          "name" => tech.name,
          "rating" => nil,
          "withdrawn" => []
        },
        %{
          "callback" => [],
          "complete" => [%{"id" => last_month_assignment.id}],
          "date" => Timex.beginning_of_month(date_in_last_month),
          "id" => tech.id,
          "name" => tech.name,
          "rating" => "5.0000000000000000",
          "withdrawn" => []
        },
        %{
          "callback" => [],
          "complete" => [],
          "date" => Timex.beginning_of_month(Timex.shift(date_in_last_month, months: -1)),
          "id" => tech.id,
          "name" => tech.name,
          "rating" => nil,
          "withdrawn" => []
        },
        %{
          "callback" => [],
          "complete" => [],
          "date" => Timex.beginning_of_month(Timex.shift(date_in_last_month, months: -2)),
          "id" => tech.id,
          "name" => tech.name,
          "rating" => nil,
          "withdrawn" => []
        },
        %{
          "callback" => [],
          "complete" => [],
          "date" => Timex.beginning_of_month(Timex.shift(date_in_last_month, months: -3)),
          "id" => tech.id,
          "name" => tech.name,
          "rating" => nil,
          "withdrawn" => []
        },
        %{
          "callback" => [],
          "complete" => [],
          "date" => Timex.beginning_of_month(Timex.shift(date_in_last_month, months: -4)),
          "id" => tech.id,
          "name" => tech.name,
          "rating" => nil,
          "withdrawn" => []
        }
      ]
      # we need to do this to get the right formatting for the datetimes
      |> Jason.encode!()
      |> Jason.decode!()

    conn =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/techs/#{tech.id}?pastStats=true")

    assert json_response(conn, 200) == expected
  end

  test "GET api/techs/:id", ~M[admin, conn, tech] do
    expected = %{"completion_time" => nil, "rating" => nil}

    conn =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/techs/#{tech.id}")

    assert json_response(conn, 200) == expected
  end

  test "POST api/techs invalid", ~M[admin, conn, skills, property] do
    params = %{
      "tech" => %{
        "name" => "Tech Name",
        "type" => "Tech",
        "can_edit" => false,
        "email" => "tech@example.com",
        "category_ids" => Enum.map(skills, & &1.category_id),
        "property_ids" => [property.id]
      }
    }

    conn =
      conn
      |> admin_request(admin)
      |> post("https://administration.example.com/api/techs", params)

    assert json_response(conn, 400) == %{"errors" => %{"phone_number" => ["can't be blank"]}}
  end

  test "POST api/techs", ~M[admin, conn, skills, property] do
    params = %{
      "tech" => %{
        "name" => "Tech Name",
        "phone_number" => "5555555555",
        "type" => "Tech",
        "can_edit" => false,
        "email" => "tech@example.com",
        "category_ids" => Enum.map(skills, & &1.category_id),
        "property_ids" => [property.id]
      }
    }

    conn =
      conn
      |> admin_request(admin)
      |> post("https://administration.example.com/api/techs", params)

    tech =
      Repo.get_by(Maintenance.Tech, [name: "Tech Name"], prefix: "dasmen")
      |> Repo.preload([:skills, :jobs])

    assert tech
    assert length(tech.skills) == 2
    assert hd(tech.jobs).property_id == property.id

    assert json_response(conn, 200) == %{}
  end

  test "PATCH api/techs/:id all_categories", ~M[admin, conn, tech] do
    unassigned = insert(:category)

    params = %{
      "all_categories" => nil
    }

    reloaded =
      Repo.get(Maintenance.Tech, tech.id, prefix: "dasmen")
      |> Repo.preload(:skills)
      |> Map.get(:skills)

    assert length(reloaded) == 2

    conn =
      conn
      |> admin_request(admin)
      |> patch("https://administration.example.com/api/techs/#{tech.id}", params)

    reloaded =
      Repo.get(Maintenance.Tech, tech.id, prefix: "dasmen")
      |> Repo.preload(:skills)
      |> Map.get(:skills)

    assert length(reloaded) == 3
    assert Enum.find(reloaded, &(&1.category_id == unassigned.id))

    assert json_response(conn, 200) == %{}
  end

  test "PATCH api/techs/:id", ~M[admin, conn, tech] do
    new_property = insert(:property)
    params = %{"tech" => %{"name" => "Somebody Hasaname", "property_ids" => [new_property.id]}}

    conn =
      conn
      |> admin_request(admin)
      |> patch("https://administration.example.com/api/techs/#{tech.id}", params)

    reloaded =
      Repo.get(Maintenance.Tech, tech.id, prefix: "dasmen")
      |> Repo.preload(:jobs)

    assert reloaded.name == "Somebody Hasaname"
    assert length(reloaded.jobs) == 1
    assert hd(reloaded.jobs).property_id == new_property.id

    assert json_response(conn, 200) == %{}
  end

  test "PATCH api/techs/:id pass_code", ~M[admin, conn, tech] do
    params = %{"pass_code" => nil}

    conn =
      conn
      |> admin_request(admin)
      |> patch("https://administration.example.com/api/techs/#{tech.id}", params)

    reloaded = Repo.get(Maintenance.Tech, tech.id, prefix: "dasmen")

    assert is_binary(reloaded.pass_code)

    assert json_response(conn, 200) == %{}
  end

  test "DELETE api/techs/:id", ~M[admin, conn, tech] do
    conn =
      conn
      |> admin_request(admin)
      |> delete("https://administration.example.com/api/techs/#{tech.id}")

    refute Repo.get(Maintenance.Tech, tech.id, prefix: "dasmen")
    assert json_response(conn, 200) == %{}
  end
end
