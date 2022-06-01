defmodule AppCount.Maintenance.InsightReports.UnitTalliesTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.Utils.Cards

  describe "call/2" do
    setup do
      date = Timex.now()

      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()

      ~M[date, builder]
    end

    test "with one vacant unrented ready unit", ~M[date, builder] do
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

      result = AppCount.Maintenance.Utils.Cards.ready_and_not_ready_count(property)

      assert %{ready: 1} = result
    end

    test "with one not ready unit", ~M[date, builder] do
      lease_start = Timex.shift(date, days: -400) |> Timex.to_date()
      lease_end = Timex.shift(date, days: -5) |> Timex.to_date()
      notice_date = Timex.shift(date, days: -25) |> Timex.to_date()
      actual_move_out = Timex.shift(date, days: -5) |> Timex.to_date()

      # We need a "completed" Card as well as a unit with a lease where there is
      # an "Actual Move Out" field (on that most recent lease).

      card_attrs = [
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
        |> PropBuilder.add_card(card_attrs)
        |> PropBuilder.get_requirement(:property)

      # When
      result = AppCount.Maintenance.Utils.Cards.ready_and_not_ready_count(property)

      assert %{not_ready: 1} = result
    end

    test "with one not ready unit, but it's HIDDEN", ~M[date, builder] do
      lease_start = Timex.shift(date, days: -400) |> Timex.to_date()
      lease_end = Timex.shift(date, days: -5) |> Timex.to_date()
      notice_date = Timex.shift(date, days: -25) |> Timex.to_date()
      actual_move_out = Timex.shift(date, days: -5) |> Timex.to_date()

      # We need a "completed" Card as well as a unit with a lease where there is
      # an "Actual Move Out" field (on that most recent lease).

      card_attrs = [
        completion: nil,
        hidden: true
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

      # When
      # this looks like a misplaced test
      result = AppCount.Maintenance.Utils.Cards.ready_and_not_ready_count(property)

      assert %{not_ready: 0} = result
    end

    test "with one ready unit, but it's HIDDEN like a dastardly vampire", ~M[date, builder] do
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
        },
        hidden: true
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

      # When
      result = Cards.ready_and_not_ready_count(property)

      assert %{not_ready: 0} = result
    end
  end
end
