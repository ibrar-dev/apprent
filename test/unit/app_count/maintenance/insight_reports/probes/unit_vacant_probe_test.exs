defmodule AppCount.Maintenance.InsightReports.UnitVacantProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.UnitVacantProbe

  test "insight_item", ~M[  today_range, property] do
    daily_context = ProbeContext.new([], [], property, today_range)

    # When
    insight_item = UnitVacantProbe.insight_item(daily_context)

    assert insight_item.comments == []
  end

  describe "call/1" do
    setup do
      date = Timex.now()

      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()

      ~M[date, builder]
    end

    test "returns 0 for a property with no units", ~M[builder] do
      property =
        builder
        |> PropBuilder.get_requirement(:property)

      unit_tallies = AppCount.Maintenance.Utils.Cards.ready_and_not_ready_count(property)
      result = UnitVacantProbe.call(unit_tallies)

      assert result == 0
    end

    test "with a property with 1 unit not represented on make-ready board", ~M[builder] do
      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.get_requirement(:property)

      unit_tallies = AppCount.Maintenance.Utils.Cards.ready_and_not_ready_count(property)
      result = UnitVacantProbe.call(unit_tallies)

      assert result == 0
    end

    test "with one vacant ready unit", ~M[date, builder] do
      lease_start = Timex.shift(date, days: -400) |> Timex.to_date()
      lease_end = Timex.shift(date, days: -5) |> Timex.to_date()
      notice_date = Timex.shift(date, days: -25) |> Timex.to_date()
      actual_move_out = Timex.shift(date, days: -5) |> Timex.to_date()

      # We need a "completed" Card as well as a unit with a lease where there is
      # an "Actual Move Out" field (on that most recent lease).

      card_attrs = [
        completion: %{
          "date" => DateTime.to_iso8601(date),
          "name" => "blah"
        }
      ]

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease(
          end_date: lease_end,
          start_date: lease_start,
          notice_date: notice_date,
          actual_move_out: actual_move_out
        )
        |> PropBuilder.add_card(card_attrs)
        |> PropBuilder.get_requirement(:property)

      unit_tallies = AppCount.Maintenance.Utils.Cards.ready_and_not_ready_count(property)
      result = UnitVacantProbe.call(unit_tallies)

      assert result == 1
    end

    test "with one vacant rented not-ready unit", ~M[date, builder] do
      lease_start = Timex.shift(date, days: -400) |> Timex.to_date()
      lease_end = Timex.shift(date, days: -5) |> Timex.to_date()
      notice_date = Timex.shift(date, days: -25) |> Timex.to_date()
      actual_move_out = Timex.shift(date, days: -5) |> Timex.to_date()

      # We need a "completed" Card as well as a unit with a lease where there is
      # an "Actual Move Out" field (on that most recent lease).

      card_attrs_open = [
        completion: nil
      ]

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease(
          end_date: lease_end,
          start_date: lease_start,
          notice_date: notice_date,
          actual_move_out: actual_move_out
        )
        |> PropBuilder.add_card(card_attrs_open)
        |> PropBuilder.get_requirement(:property)

      unit_tallies = AppCount.Maintenance.Utils.Cards.ready_and_not_ready_count(property)
      result = UnitVacantProbe.call(unit_tallies)

      assert result == 1
    end

    test "with one of each", ~M[date, builder] do
      lease_start = Timex.shift(date, days: -400) |> Timex.to_date()
      lease_end = Timex.shift(date, days: -5) |> Timex.to_date()
      notice_date = Timex.shift(date, days: -25) |> Timex.to_date()
      actual_move_out = Timex.shift(date, days: -5) |> Timex.to_date()

      # We need a "completed" Card as well as a unit with a lease where there is
      # an "Actual Move Out" field (on that most recent lease).

      card_attrs_open = [
        completion: nil
      ]

      card_attrs_closed = [
        completion: %{
          "date" => DateTime.to_iso8601(date),
          "name" => "blah"
        }
      ]

      card_attrs_hidden = [
        completion: %{
          "date" => DateTime.to_iso8601(date),
          "name" => "blah"
        },
        hidden: true
      ]

      property =
        builder
        # Add a not ready unit
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease(
          end_date: lease_end,
          start_date: lease_start,
          notice_date: notice_date,
          actual_move_out: actual_move_out
        )
        |> PropBuilder.add_card(card_attrs_open)
        # Add another unit - this one is "complete" and ready
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease(
          end_date: lease_end,
          start_date: lease_start,
          notice_date: notice_date,
          actual_move_out: actual_move_out
        )
        |> PropBuilder.add_card(card_attrs_closed)
        # Add another unit - this one is not on the make-ready board
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease(
          end_date: lease_end,
          start_date: lease_start,
          notice_date: notice_date,
          actual_move_out: actual_move_out
        )
        |> PropBuilder.add_card(card_attrs_hidden)
        |> PropBuilder.get_requirement(:property)

      unit_tallies = AppCount.Maintenance.Utils.Cards.ready_and_not_ready_count(property)
      result = UnitVacantProbe.call(unit_tallies)

      assert result == 2
    end
  end
end
