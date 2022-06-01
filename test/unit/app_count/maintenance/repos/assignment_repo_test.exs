defmodule AppCount.Maintenance.AssignmentRepoTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.AssignmentRepo
  alias AppCount.Core.DateTimeRange

  describe "property" do
    setup do
      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_tech()

      ~M[builder]
    end

    test "ONE work order without callback", ~M[builder] do
      builder =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()
        |> PropBuilder.add_work_order_on_unit()

      property = PropBuilder.get_requirement(builder, :property)

      date_range = DateTimeRange.today()

      assignments = AssignmentRepo.get_callback_assignments(property, date_range)

      assert assignments == []
    end
  end

  describe "property with callback assignment" do
    setup do
      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_tech()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()
        |> PropBuilder.add_work_order_on_unit()

      property = PropBuilder.get_requirement(builder, :property)
      admin = Factory.admin_with_access([property.id])
      from = naive_now() |> NaiveDateTime.add(-4 * 60 * 60, :second)
      client = AppCount.Public.get_client_by_schema("dasmen")

      builder =
        builder
        |> PropBuilder.create_unit_work_order(from, admin, client.client_schema)

      assignment = PropBuilder.get_requirement(builder, :assignment)
      {:ok, callback_assignment} = AssignmentRepo.update(assignment, %{status: "callback"})

      ~M[ property, assignment, callback_assignment ]
    end

    test "assignment with callback preloads associations", ~M[ property ] do
      date_range = DateTimeRange.today()
      # When
      [assignment] = AssignmentRepo.get_callback_assignments(property, date_range)

      assert Ecto.assoc_loaded?(assignment.tech)
      assert Ecto.assoc_loaded?(assignment.order)
      assert Ecto.assoc_loaded?(assignment.order.unit)
    end

    test "today's assignment with callback found for today's query",
         ~M[ property,  callback_assignment ] do
      callback_assignment = Repo.preload(callback_assignment, [:tech, order: [:unit]])

      date_range = DateTimeRange.today()
      # When
      assignments = AssignmentRepo.get_callback_assignments(property, date_range)

      assert assignments == [callback_assignment]
    end

    test "yesterday's assignment with callback not found today",
         ~M[ property, assignment ] do
      {:ok, _todays_assignment} = AssignmentRepo.update(assignment, %{status: "callback"})

      date_range = DateTimeRange.yesterday()
      # When
      assignments = AssignmentRepo.get_callback_assignments(property, date_range)

      assert assignments == []
    end
  end

  describe "assignments across properties" do
    setup do
      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_tech()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()
        |> PropBuilder.add_work_order_on_unit()

      property = PropBuilder.get_requirement(builder, :property)
      admin = Factory.admin_with_access([property.id])
      from = naive_now() |> NaiveDateTime.add(-4 * 60 * 60, :second)

      builder =
        builder
        |> PropBuilder.create_open_unit_work_order(from, admin)

      assignment = PropBuilder.get_requirement(builder, :assignment)

      date_range = DateTimeRange.today()

      ~M[ property, builder, assignment, date_range, admin, from ]
    end

    test "filters by property", ~M[property, builder, assignment, date_range, from, admin] do
      # Set up assignment, etc., for another property
      builder
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_unit_category()
      |> PropBuilder.add_work_order_on_unit()
      |> PropBuilder.create_open_unit_work_order(from, admin)

      assignments = AssignmentRepo.get_property_assignments(property, date_range)

      assert length(assignments) == 1
      [found_assignment] = assignments

      assert found_assignment.id == assignment.id
    end
  end

  describe "property with open and complete assignments" do
    setup do
      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_tech()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()
        |> PropBuilder.add_work_order_on_unit()

      property = PropBuilder.get_requirement(builder, :property)
      admin = Factory.admin_with_access([property.id])
      from = naive_now() |> NaiveDateTime.add(-4 * 60 * 60, :second)

      builder =
        builder
        |> PropBuilder.create_open_unit_work_order(from, admin)

      assignment = PropBuilder.get_requirement(builder, :assignment)

      now = DateTime.utc_now()
      date_range = DateTimeRange.today()

      ~M[ property, assignment, date_range, now ]
    end

    test "open assignment", ~M[ property,  assignment, date_range] do
      # When
      [found_assignment] = AssignmentRepo.get_property_assignments(property, date_range)

      assert found_assignment.id == assignment.id
      refute found_assignment.completed_at
    end

    test "today's completed assignment", ~M[ property,  assignment, date_range, now ] do
      {:ok, _completed_assignment} = AssignmentRepo.update(assignment, %{completed_at: now})
      # When
      [found_assignment] = AssignmentRepo.get_property_assignments(property, date_range)

      assert found_assignment.id == assignment.id
      assert found_assignment.completed_at
    end
  end
end
