# TODO: this is not a full integration test yet, some of
# the requests here have effects that need to be asserted
defmodule AppCountWeb.TechChannelTest do
  use AppCountWeb.ChannelCase
  import AppCount.Factory
  alias AppCountWeb.TechSocket
  alias AppCountWeb.TechChannel
  alias AppCount.Maintenance.Timecard
  alias AppCount.Repo

  setup do
    pass_code = UUID.uuid4()
    tech = insert(:tech, pass_code: pass_code)
    {:ok, cert, _} = AppCount.Maintenance.cert_for_passcode(pass_code)
    {:ok, socket} = TechSocket.connect(%{"cert" => cert}, socket(TechSocket))

    {:ok, _, socket} =
      socket
      |> subscribe_and_join(TechChannel, "tech_mobile")

    %{socket: socket, tech: tech, assignment: insert(:assignment, tech: tech)}
  end

  def wait_for_socket_work_to_finish(ref) do
    assert_reply ref, :ok, nil, 1500
  end

  test "COMPLETE", %{socket: socket, assignment: assignment} do
    details = %{"tech_comments" => "Ac repaired \n"}
    ref = push(socket, "COMPLETE", %{"id" => assignment.id, "details" => details})
    wait_for_socket_work_to_finish(ref)
    reloaded = Repo.get(AppCount.Maintenance.Assignment, assignment.id, prefix: "dasmen")
    assert reloaded.status == "completed"
  end

  test "NOTIFY", %{socket: socket, assignment: assignment} do
    params = %{"id" => assignment.id, "time" => 15}
    ref = push(socket, "NOTIFY", params)
    wait_for_socket_work_to_finish(ref)
  end

  test "NOTIFICATION_TOKEN", %{socket: socket, tech: tech} do
    params = %{"name" => "Joke"}
    ref = push(socket, "NOTIFICATION_TOKEN", params)
    wait_for_socket_work_to_finish(ref)
    reloaded = Repo.get(AppCount.Maintenance.Tech, tech.id, prefix: tech.__meta__.prefix)
    assert reloaded.name == "Joke"
  end

  test "RESUME", %{socket: socket, assignment: assignment} do
    params = %{"id" => assignment.id}
    push(socket, "RESUME", params)
    # We need to assert this twice because :after_join pushes the same result
    assert_push "DATA", %{assignments: _}
    assert_push "DATA", %{assignments: _}
  end

  test "GET_CLOCK_STATUS", %{socket: socket, tech: tech} do
    insert(:timecard, tech: tech)
    push(socket, "GET_CLOCK_STATUS", nil)
    assert_push "CLOCK", %{status: true}
  end

  test "REJECT", %{socket: socket, assignment: assignment} do
    message = %{"reason" => "I do not like this tenant", "id" => assignment.id}
    ref = push(socket, "REJECT", message)
    wait_for_socket_work_to_finish(ref)
    reloaded = Repo.get(AppCount.Maintenance.Assignment, assignment.id, prefix: "dasmen")
    assert reloaded.status == "withdrawn"
  end

  test "CLOCK", %{socket: socket, tech: tech} do
    loc = %{"coord" => "My House"}
    params = %{"location" => loc, "id" => tech.id}
    ref = push(socket, "CLOCK", params)
    wait_for_socket_work_to_finish(ref)
    card = Repo.get_by(Timecard, [tech_id: tech.id], prefix: "dasmen")
    assert card.start_location == loc
  end

  test "FETCH_ORDER", %{socket: socket} do
    params = %{"id" => 0}
    push(socket, "FETCH_ORDER", params)
    assert_push "ORDER_DATA", nil
  end

  test "GET_PROFILE", %{socket: socket} do
    push(socket, "GET_PROFILE", nil)

    assert_push "PROFILE", %{info: %{id: _}}
  end

  test "UPDATE_INVENTORY", %{socket: socket, assignment: assignment} do
    # apparently this is how it comes over from the frontend...
    params = %{
      "inventory" => %{
        "inventory" => [
          %{"id" => insert(:toolbox_item).id, "assignment_id" => assignment.id}
        ]
      }
    }

    push(socket, "UPDATE_INVENTORY", params)
    assert_push "TOOLBOX", %{toolbox: _}
  end

  test "UPDATE_PROFILE", %{socket: socket} do
    # apparently this is how it comes over from the frontend...
    params = %{
      "name" => "New Tech Name"
    }

    push(socket, "UPDATE_PROFILE", params)
    assert_push "PROFILE", %{info: %{id: _, name: "New Tech Name"}}
  end

  test "COORDINATES", %{socket: socket} do
    params = %{
      "lat" => 111,
      "lng" => 234
    }

    AppCountWeb.Endpoint.subscribe("tech_admin")
    push(socket, "COORDINATES", params)

    assert_broadcast "COORDINATES", %{
      msg: %{lat: 111, lng: 234, tech_id: _}
    }
  end

  test "SCAN", %{socket: socket, assignment: assignment} do
    push(socket, "SCAN", %{"id" => assignment.id, "ref" => "12345"})
    assert_push "SCAN", %{}
  end

  test "ATTACH_ITEMS", %{socket: socket, assignment: assignment} do
    params = %{
      "inventory" => [%{"id" => insert(:toolbox_item).id, "assignment_id" => assignment.id}]
    }

    push(socket, "ATTACH_ITEMS", params)
    assert_push "TOOLBOX", %{toolbox: _}
  end

  test "REMOVE_MAT", %{socket: socket, assignment: assignment} do
    params = %{"id" => assignment.id, "material" => %{"num" => 0, "name" => "nails"}}
    push(socket, "REMOVE_MAT", params)
    # We need to assert this twice because :after_join pushes the same result
    assert_push "DATA", %{assignments: _}
    assert_push "DATA", %{assignments: _}
  end

  test "NO_ACCESS", %{socket: socket, assignment: assignment} do
    params = %{"order_id" => assignment.order.id, "assignment_id" => assignment.id}
    push(socket, "NO_ACCESS", params)
    assert_push "DATA", %{assignments: [%{status: "on_hold"}]}
  end

  test "PAUSE", %{socket: socket, assignment: assignment} do
    params = %{"id" => assignment.id}
    push(socket, "PAUSE", params)
    assert_push "DATA", %{assignments: [%{status: "on_hold"}]}
  end

  test "NOTE", %{socket: socket, assignment: assignment} do
    params = %{"id" => assignment.id, "note" => %{"text" => "I'm pretty sure this is noteworthy"}}
    push(socket, "NOTE", params)
    assert_push "ORDER_DATA", _
  end

  test "CONFIRM", %{socket: socket, assignment: assignment} do
    params = %{"id" => assignment.id}

    push(socket, "CONFIRM", params)
    |> wait_for_socket_work_to_finish
  end

  test "GET_TOOLBOX", %{socket: socket} do
    push(socket, "GET_TOOLBOX", nil)
    |> wait_for_socket_work_to_finish
  end
end
