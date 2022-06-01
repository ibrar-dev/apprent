defmodule AppCountWeb.Requests.API.AssignmentsTest do
  use AppCountWeb.ConnCase
  use AppCount.DataCase
  alias AppCount.Maintenance
  alias AppCount.Support.HTTPClient
  use Bamboo.Test

  setup do
    property = insert(:property)
    order = insert(:order, tenant: insert(:tenant, phone: "4148631356"))
    tech = insert(:tech)

    {:ok,
     order: order,
     tech: tech,
     admin: %{id: insert(:admin).id, property_ids: [property.id], roles: ["Tech"]}}
  end

  test "POST /api/assignments assignment", %{conn: conn, admin: admin, order: order, tech: tech} do
    params = %{
      "assignment" => %{
        "order_id" => order.id,
        "tech_id" => tech.id
      }
    }

    conn =
      conn
      |> admin_request(admin)
      |> post("https://administration.example.com/api/assignments", params)

    assignment =
      Repo.get_by(Maintenance.Assignment, [order_id: order.id, tech_id: tech.id], prefix: "dasmen")

    assert assignment
    assert assignment.status == "on_hold"
    assert assignment.tech_id == tech.id

    reloaded_order = Repo.get(Maintenance.Order, order.id)
    assert reloaded_order.status == "assigned"

    assert_email_delivered_with(
      subject: "[AppRent] Your service request, #{order.ticket} has been assigned",
      html_body: ~r/and is scheduled to be addressed in the 24-48 hours/,
      to: [
        nil: order.tenant.email
      ]
    )

    assert json_response(conn, 200) == %{}
  end

  test "POST /api/assignments order_ids tech_id", %{
    conn: conn,
    admin: admin,
    order: order,
    tech: tech
  } do
    order2 = insert(:order)

    params = %{
      "order_ids" => [order.id, order2.id],
      "tech_id" => tech.id
    }

    conn =
      conn
      |> admin_request(admin)
      |> post("https://administration.example.com/api/assignments", params)

    assignment =
      Repo.get_by(Maintenance.Assignment, [order_id: order.id, tech_id: tech.id], prefix: "dasmen")

    assert assignment
    assert assignment.status == "on_hold"
    assert assignment.tech_id == tech.id

    assignment2 =
      Repo.get_by(Maintenance.Assignment, [order_id: order2.id, tech_id: tech.id],
        prefix: "dasmen"
      )

    assert assignment2
    assert assignment2.status == "on_hold"
    assert assignment2.tech_id == tech.id

    assert json_response(conn, 200) == %{}
  end

  describe "update" do
    setup context do
      insert(:user_account, tenant: context.order.tenant, allow_sms: true)
      {:ok, assignment: insert(:assignment, order: context.order)}
    end

    test "PATCH /api/assignments/:id bug", %{conn: conn, admin: admin, assignment: assignment} do
      conn =
        conn
        |> admin_request(admin)
        |> patch("https://administration.example.com/api/assignments/#{assignment.id}", %{
          "bug" => "true"
        })

      assert_email_delivered_with(
        subject: "[AppRent] Reminder to rate your recent order",
        html_body: ~r/Your work order ##{assignment.order.ticket} has been completed\./,
        to: [
          nil: assignment.order.tenant.email
        ]
      )

      assert json_response(conn, 200) == %{}
    end

    test "PATCH /api/assignments/:id rating", %{conn: conn, admin: admin, assignment: assignment} do
      conn
      |> admin_request(%{admin | roles: ["Super Admin"]})
      |> patch("https://administration.example.com/api/assignments/#{assignment.id}", %{
        "rating" => 3
      })

      reloaded = Repo.get(AppCount.Maintenance.Assignment, assignment.id)
      assert reloaded.rating == 3
    end

    test "PATCH /api/assignments/:id assignment_id time", %{
      conn: conn,
      admin: admin,
      assignment: assignment
    } do
      HTTPClient.initialize([Jason.encode!(%{})], self())
      params = %{"assignment_id" => assignment.id, "time" => 18}

      conn =
        conn
        |> admin_request(admin)
        |> patch("https://administration.example.com/api/assignments/#{assignment.id}", params)

      assert_email_delivered_with(
        subject: "[AppRent] Your tech for #{assignment.order.ticket} is on their way",
        html_body: ~r/They will be there in approximately 18 minutes./,
        to: [
          nil: assignment.order.tenant.email
        ]
      )

      twilio_headers =
        AppCount.Adapters.Twilio.Credential.load()
        |> AppCount.Adapters.TwilioAdapter.headers_with()

      twilio_sid = Application.get_env(:app_count, AppCount.Adapters.Twilio.Credential)[:sid]
      url = "https://api.twilio.com/2010-04-01/Accounts/#{twilio_sid}/Messages.json"
      body = "Body=Hi+#{assignment.order.tenant.first_name}%2C+Some+Guy+from+Test+Property+is+on+the+way+to+address+your+maintenance+request+for+#{
        assignment.order.category.name
      }.+You+will+receive+another+notification+when+the+job+is+done.&From=%2B15005550006&To=%2B1#{
        assignment.order.tenant.phone
      }"

      assert_receive {"POST", ^url, ^twilio_headers, ^body, []}, 500
      assert json_response(conn, 200) == %{}
      HTTPClient.stop()
    end

    test "PATCH /api/assignments/:id callback note", %{
      conn: conn,
      admin: admin,
      assignment: assignment
    } do
      params = %{"callback" => true, "note" => "I have no time"}

      conn =
        conn
        |> admin_request(admin)
        |> patch("https://administration.example.com/api/assignments/#{assignment.id}", params)

      reloaded = Repo.get(AppCount.Maintenance.Assignment, assignment.id)
      assert reloaded.status == "callback"
      assert json_response(conn, 200) == %{}
    end

    test "PATCH /api/assignments/:id callback", %{
      conn: conn,
      admin: admin,
      assignment: assignment
    } do
      params = %{"callback" => true, "note" => "I have no time"}

      conn =
        conn
        |> admin_request(admin)
        |> patch("https://administration.example.com/api/assignments/#{assignment.id}", params)

      reloaded = Repo.get(AppCount.Maintenance.Assignment, assignment.id)
      assert reloaded.status == "callback"
      assert json_response(conn, 200) == %{}
    end
  end

  test "DELETE /api/assignments/:id assignment_ids" do
  end

  test "DELETE /api/assignments/:id trueDelete" do
  end

  test "DELETE /api/assignments/:id" do
  end
end
