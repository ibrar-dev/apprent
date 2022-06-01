defmodule AppCount.Reports.Queries.UnitStatusTest do
  alias AppCount.Reports.Queries.UnitStatus
  use AppCount.DataCase

  describe "get_status/2" do
    setup do
      date = Timex.now() |> Timex.to_date()

      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()

      ~M[date, builder]
    end

    test "with for a property with 1 unrented unready unit", ~M[date, builder] do
      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.get_requirement(:property)

      [unit] = UnitStatus.full_unit_status(property.id, date) |> Repo.all()

      assert "Vacant Unrented Not Ready" == unit.status
    end

    test "with one rented unit", ~M[date, builder] do
      lease_start = Timex.shift(date, days: -45)
      DateRange

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_customer_ledger()
        |> PropBuilder.add_tenancy(start_date: lease_start)
        |> PropBuilder.get_requirement(:property)

      [unit] = UnitStatus.full_unit_status(property.id, date) |> Repo.all()

      assert "Occupied" == unit.status
    end

    test "with one vacant unrented ready unit", ~M[date, builder] do
      lease_start = Timex.shift(date, days: -400)
      notice_date = Timex.shift(date, days: -25)
      actual_move_out = Timex.shift(date, days: -5)

      # We need a "completed" Card as well as a unit with a lease where there is
      # an "Actual Move Out" field (on that most recent lease).

      card_attrs = [
        completion: %{
          "date" => Date.to_iso8601(date),
          "name" => "blah"
        }
      ]

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_customer_ledger()
        |> PropBuilder.add_tenancy(
          start_date: lease_start,
          notice_date: notice_date,
          actual_move_out: actual_move_out
        )
        |> PropBuilder.add_card(card_attrs)
        |> PropBuilder.get_requirement(:property)

      [unit] = UnitStatus.full_unit_status(property.id, date) |> Repo.all()

      assert "Vacant Unrented Ready" == unit.status
    end

    test "with one vacant rented ready unit", ~M[date, builder] do
      lease_start = Timex.shift(date, days: -400)
      notice_date = Timex.shift(date, days: -25)
      actual_move_out = Timex.shift(date, days: -5)

      # We need a "completed" Card as well as a unit with a lease where there is
      # an "Actual Move Out" field (on that most recent lease).
      #
      # We also need an impending lease that hasn't started yet

      new_lease_start = Timex.shift(date, days: 20)

      card_attrs = [
        completion: %{
          "date" => Date.to_iso8601(date),
          "name" => "blah"
        }
      ]

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_customer_ledger()
        |> PropBuilder.add_tenancy(
          start_date: lease_start,
          notice_date: notice_date,
          actual_move_out: actual_move_out
        )
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_customer_ledger()
        |> PropBuilder.add_tenancy(
          start_date: new_lease_start,
          actual_move_in: nil,
          expected_move_in: new_lease_start
        )
        |> PropBuilder.add_card(card_attrs)
        |> PropBuilder.get_requirement(:property)

      [unit] = UnitStatus.full_unit_status(property.id, date) |> Repo.all()

      assert "Vacant Rented Ready" == unit.status
    end

    test "with one vacant rented not-ready unit", ~M[date, builder] do
      # Lease starts in the future; haven't yet moved in
      lease_start = Timex.shift(date, days: 45)
      actual_move_in = nil
      expected_move_in = Timex.shift(date, days: 50)

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_customer_ledger()
        |> PropBuilder.add_tenancy(
          start_date: lease_start,
          actual_move_in: actual_move_in,
          expected_move_in: expected_move_in
        )
        |> PropBuilder.get_requirement(:property)

      [unit] = UnitStatus.full_unit_status(property.id, date) |> Repo.all()

      assert "Vacant Rented Not Ready" == unit.status
    end

    test "with renovated unit", ~M[date, builder] do
      property =
        builder
        |> PropBuilder.add_unit(status: "RENO")
        |> PropBuilder.get_requirement(:property)

      [unit] = UnitStatus.full_unit_status(property.id, date) |> Repo.all()

      assert "RENO" == unit.status
    end

    test "with DOWN unit", ~M[date, builder] do
      property =
        builder
        |> PropBuilder.add_unit(status: "DOWN")
        |> PropBuilder.get_requirement(:property)

      [unit] = UnitStatus.full_unit_status(property.id, date) |> Repo.all()

      assert "DOWN" == unit.status
    end

    test "with a notice rented unit", ~M[date, builder] do
      # We will move out soon and have already given notice
      old_lease_start = Timex.shift(date, days: -365)
      notice_date = Timex.shift(date, days: -25)

      new_lease_start = Timex.shift(date, days: 10)

      property =
        builder
        |> PropBuilder.add_unit()
        # Add our expiring lease
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_customer_ledger()
        |> PropBuilder.add_tenancy(
          start_date: old_lease_start,
          notice_date: notice_date
        )
        # Add a new lease
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_customer_ledger()
        |> PropBuilder.add_tenancy(
          start_date: new_lease_start,
          actual_move_in: nil
        )
        |> PropBuilder.get_requirement(:property)

      [unit] = UnitStatus.full_unit_status(property.id, date) |> Repo.all()

      assert "Notice Rented" == unit.status
    end

    test "with a notice unrented unit", ~M[date, builder] do
      # We will move out soon and have already given notice
      lease_start = Timex.shift(date, days: -365)
      notice_date = Timex.shift(date, days: -25)

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_customer_ledger()
        |> PropBuilder.add_tenancy(
          start_date: lease_start,
          notice_date: notice_date
        )
        |> PropBuilder.get_requirement(:property)

      [unit] = UnitStatus.full_unit_status(property.id, date) |> Repo.all()

      assert "Notice Unrented" == unit.status
    end
  end
end
