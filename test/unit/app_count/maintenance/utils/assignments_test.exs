defmodule AppCount.Maintenance.Utils.AssignmentsTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Utils.Assignments
  alias AppCount.Maintenance.OrderRepo
  alias AppCount.Core.ClientSchema

  @moduletag :utils_assignments

  describe "debugging get_reminder_to_rate_order_info" do
    test " valid email info" do
      order = Factory.insert(:order)
      order = OrderRepo.get_aggregate(order.id)
      assignment = Factory.insert(:assignment, order: order)
      # When
      result = Assignments.get_reminder_to_rate_order_info(assignment)
      # Then
      {tenant_name, "UNKNOWN", tenant_email, _property, order_id} = result
      assert tenant_name =~ ~r/Larry-\d+ Smith/
      assert tenant_email =~ ~r/someguy\d+@yahoo.com/
      assert order_id == order.id
    end

    test "deleted order" do
      order = Factory.insert(:order)
      order = OrderRepo.get_aggregate(order.id)
      assignment = Factory.insert(:assignment, order: order)
      ##
      {:ok, _ex_order} = OrderRepo.delete(order.id)
      # When
      result = Assignments.get_reminder_to_rate_order_info(assignment)
      # Then
      assert nil == result
    end
  end

  describe "assign_order " do
    setup do
      new_admin = AppCount.UserHelper.new_admin()
      {:ok, order: insert(:order), tech: insert(:tech), admin: new_admin}
    end

    # This test passes when the controller does not work and fails when the controller does work.
    test "multiple", %{order: order, tech: tech, admin: admin} do
      ClientSchema.new(order.__meta__.prefix, [order.id])
      |> Assignments.assign_orders(tech.id, admin.id)

      assert Repo.get_by(Assignment, tech_id: tech.id, admin_id: admin.id, order_id: order.id)
    end

    test "with no assignment", %{order: order, tech: tech, admin: admin} do
      ClientSchema.new(order.__meta__.prefix, order.id)
      |> Assignments.assign_order(tech.id, admin.id)

      assert Repo.get_by(Assignment, tech_id: tech.id, admin_id: admin.id, order_id: order.id)
    end

    test "with assignment in progress", %{order: order, tech: tech, admin: admin} do
      assignment = insert(:assignment, order: order, status: "in_progress")

      ClientSchema.new(order.__meta__.prefix, order.id)
      |> Assignments.assign_order(tech.id, admin.id)

      assert Repo.get_by(Assignment, tech_id: tech.id, admin_id: admin.id, order_id: order.id)
      refute Repo.get(Assignment, assignment.id)
    end

    test "with dupe assignment", %{order: order, tech: tech, admin: admin} do
      insert(:assignment, order: order)

      ClientSchema.new(order.__meta__.prefix, order.id)
      |> Assignments.assign_order(tech.id, admin.id)

      refute Repo.get_by(Assignment, [tech_id: tech.id, admin_id: admin.id, order_id: order.id],
               prefix: order.__meta__.prefix
             )
    end
  end

  describe "assignment " do
    # WE SHOULD DO SOMETHING ABOUT THESE TESTS THAT FAIL BC THEY ARE OFF BY LESS THAN A MICROSECOND
    setup do
      assignment = insert(:assignment)
      second_assignment = insert(:assignment)
      {:ok, [assignment: assignment, second_assignment: second_assignment]}
    end

    test "pause  ", context do
      current_ts = :os.system_time(:seconds)

      %ClientSchema{name: "dasmen", attrs: context.assignment.id}
      |> Assignments.pause_assignment(current_ts)

      reloaded = AppCount.Repo.get(Assignment, context.assignment.id, prefix: "dasmen")
      assert reloaded.status == "on_hold"
      assert reloaded.history == [%{"paused" => current_ts}]
    end

    test "resume  ", context do
      current_ts = :os.system_time(:seconds)
      resumed_ts = current_ts + 100

      %ClientSchema{name: "dasmen", attrs: context.assignment.id}
      |> Assignments.pause_assignment(current_ts)

      %ClientSchema{name: "dasmen", attrs: context.assignment.id}
      |> Assignments.resume_assignment(resumed_ts)

      reloaded = AppCount.Repo.get(Assignment, context.assignment.id)
      assert reloaded.status == "in_progress"
      assert reloaded.history == [%{"paused" => current_ts}, %{"resumed" => resumed_ts}]
    end

    test "complete  ", context do
      client = AppCount.Public.get_client_by_schema("dasmen")

      insert(:maintenance_note,
        order: context.assignment.order,
        tenant: context.assignment.order.tenant
      )

      # makes sure it works with multiple notes
      insert(:maintenance_note,
        order: context.assignment.order,
        tenant: context.assignment.order.tenant
      )

      OrderRepo.update(context.assignment.order, %{card_item_id: insert(:card_item).id})

      Assignments.complete_assignment(
        ClientSchema.new(client.client_schema, context.assignment.id),
        %{"tech_comments" => "Ac repaired \n"},
        insert(:tech).id
      )

      reloaded = Repo.get(Assignment, context.assignment.id)
      assert reloaded.status == "completed"
    end

    test "revoke_assignments", context do
      ClientSchema.new(context.assignment.__meta__.prefix, [
        context.assignment.id,
        context.second_assignment.id
      ])
      |> Assignments.revoke_assignments()

      refute Repo.get(Assignment, context.assignment.id)
      assert OrderRepo.get(context.assignment.order.id).status == "unassigned"
    end

    test "reject_assignment", context do
      admin_with_access([context.assignment.order.property.id], roles: ["Tech"])
      invalid = ClientSchema.new("dasmen", 0)
      assert Assignments.reject_assignment(invalid, "I am sick") == {:error, :bad_params}

      ClientSchema.new("dasmen", context.assignment.id)
      |> Assignments.reject_assignment("I am sick")

      reloaded = Repo.get(Assignment, context.assignment.id, prefix: "dasmen")
      assert reloaded.status == "withdrawn"
      assert reloaded.tech_comments == "I am sick"
      reloaded = OrderRepo.get(context.assignment.order.id)
      assert reloaded.status == "unassigned"
    end

    test "attach_material and remove_material", context do
      material = insert(:material)
      Assignments.attach_material(material.id, 2, context.assignment.id)
      reloaded = Repo.get(Assignment, context.assignment.id)

      assert reloaded.materials == [
               %{"num" => 2, "cost" => Decimal.to_float(material.cost), "name" => material.name}
             ]

      %AppCount.Core.ClientSchema{name: "dasmen", attrs: context.assignment.id}
      |> Assignments.remove_material(%{"num" => "?", "name" => material.name})

      reloaded = Repo.get(Assignment, context.assignment.id)
      assert reloaded.materials == []
    end

    # We will test the channel messages separately, for now just test that this doesn't error out
    test "notify_tech_task", context do
      result = Assignments.notify_tech_task(context.assignment)
      assert result == context.assignment
    end

    test "rate_assignment", context do
      Assignments.rate_assignment(context.assignment.id, 3)
      assert Repo.get(Assignment, context.assignment.id).rating == 3
    end

    test "delete_assignment", context do
      new_admin = AppCount.UserHelper.new_admin()

      Assignments.delete_assignment(
        ClientSchema.new(new_admin.user.client.client_schema, new_admin),
        context.assignment.id
      )

      refute Repo.get(Assignment, context.assignment.id,
               prefix: new_admin.user.client.client_schema
             )
    end

    test "bug_resident_about_rating", %{assignment: assignment} do
      Assignments.bug_resident_about_rating(%{name: "Some Admin"}, assignment.id)
      [email] = Repo.get(Assignment, assignment.id, prefix: "dasmen").email
      assert is_integer(email["time"])
      assert email["name"] == "Some Admin"
    end

    test "tech_dispatched", %{assignment: assignment} do
      %AppCount.Core.ClientSchema{name: "dasmen", attrs: assignment.id}
      |> Assignments.tech_dispatched(10)

      # TODO nothing to test here other than email being sent....
    end

    test "do_notify_tenant_assigned", %{assignment: assignment} do
      Assignments.do_notify_tenant_assigned(ClientSchema.new("dasmen", assignment))
      # TODO nothing to test here other than email being sent....
    end

    test "callback_assignment/1", %{assignment: assignment} do
      Assignments.callback_assignment(assignment)
      assert Repo.get(Assignment, assignment.id).status == "callback"
    end

    test "resident_callback_assignment/1", %{assignment: assignment} do
      Assignments.resident_callback_assignment(assignment.id, "Some note")
      reloaded = Repo.get(Assignment, assignment.id)
      assert reloaded.status == "callback"
      assert reloaded.callback_info["admin_name"] == "Resident"
      assert reloaded.callback_info["note"] == "Some note"
    end

    test "callback_assignment/3", %{assignment: assignment} do
      Assignments.callback_assignment(assignment, %{name: "SomeGuy"}, "Some note")
      reloaded = Repo.get(Assignment, assignment.id)
      assert reloaded.status == "callback"
      assert reloaded.callback_info["admin_name"] == "SomeGuy"
      assert reloaded.callback_info["note"] == "Some note"
    end

    test "list_tech_notes", %{assignment: assignment} do
      %AppCount.Core.ClientSchema{name: "dasmen", attrs: assignment.id}
      |> AppCount.Maintenance.Utils.Public.Orders.update_assignment(%{
        tech_comments: "Wow this is bad"
      })

      [%{tech: tech_id, comment: comment, id: assignment_id}] =
        Assignments.list_tech_notes(assignment.order_id)

      assert comment == "Wow this is bad"
      assert assignment_id == assignment.id
      assert tech_id == assignment.tech.name
    end
  end
end
