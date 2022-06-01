defmodule AppCount.Maintenance.InsightReports.DailyTest do
  #
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.Daily
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Order
  alias AppCount.Properties.Unit
  alias AppCount.Maintenance.Tech
  alias AppCount.Properties.Property
  alias AppCount.Core.DateTimeRange
  alias AppCount.Maintenance.InsightReports.WorkOrderViolationsProbe
  alias AppCount.Maintenance.InsightReports.MakeReadyTurnaroundProbe
  alias AppCount.Properties.PropertyRepo
  alias AppCount.Core.ClientSchema

  setup do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_unit_category()
      |> PropBuilder.add_tech()
      |> PropBuilder.add_work_order_on_unit()

    date_range_today = DateTimeRange.today()

    ~M[builder, date_range_today]
  end

  describe "generate_stats" do
    test "", ~M[builder, date_range_today] do
      property =
        builder
        |> PropBuilder.get_requirement(:property)

      expected_readings =
        [
          Reading.work_orders_submitted(1),
          Reading.work_order_completed(0),
          Reading.work_orders(1),
          # Reading.work_order_turnaround(0.0), # has timing issue in test
          Reading.work_order_saturation(100),
          Reading.work_order_rating(0),
          Reading.work_order_violations(0),
          Reading.work_order_callbacks(0),
          Reading.unit_vacant_ready(0),
          Reading.unit_vacant_not_ready(0),
          Reading.unit_vacant(0),
          Reading.make_ready_percent(0),
          Reading.make_ready_turnaround(0),
          Reading.make_ready_utilization(0.0)
        ]
        |> Reading.put_property(property.id)

      # When
      report =
        AppCount.Maintenance.InsightReports.Daily.generate_stats(
          property,
          date_range_today
        )

      # PostProcess to remove Reading with timeing issue.
      timing_issue_fn = fn reading -> reading.name == :work_order_turnaround end
      actual_readings = Enum.reject(report.data.synopsis, timing_issue_fn)
      assert actual_readings == expected_readings

      timing_issue_reading = Enum.filter(report.data.synopsis, timing_issue_fn) |> List.first()
      {timing_issue_value, :seconds} = timing_issue_reading.measure
      assert_in_delta timing_issue_value, 0, 1

      detail_comments = report.data.detail_comments

      assert "Harry does not have any assigned work orders. Please make sure that all techs have work orders assigned." in detail_comments

      assert "Work orders are looking too high with 1 open. Let's work to bring them down. You got this!" in detail_comments

      assert "If Harry was at work today, please check into why they completed zero work orders" in detail_comments

      assert "Harry does not have any assigned work orders. Please make sure that all techs have work orders assigned." in detail_comments
    end
  end

  describe "detail_comments" do
    test "one violation", ~M[builder] do
      now = DateTime.utc_now()
      date_range = DateTimeRange.new(now, now)
      task_begin = DateTime.to_naive(date_range.to) |> NaiveDateTime.truncate(:second)
      property = PropBuilder.get_requirement(builder, :property)

      admin = Factory.admin_with_access([property.id])
      client = AppCount.Public.get_client_by_schema("dasmen")

      property =
        builder
        |> PropBuilder.add_work_order_on_unit(priority: 3)
        |> PropBuilder.create_unit_work_order(task_begin, admin, client.client_schema)
        |> PropBuilder.get_requirement(:property)

      submitted_work_orders_count = PropertyRepo.get_submitted_work_orders(property, date_range)

      daily_context =
        ProbeContext.input_map(
          property: property,
          submitted_work_orders_count: submitted_work_orders_count
        )
        |> ProbeContext.new(property, date_range)

      # When
      daily_context = Daily.apply_probes(daily_context)

      expected =
        "Urgent! There is 1 open City Code violation. Please resolve this as quickly as possible."

      assert expected in daily_context.comments
    end
  end

  describe "assignments with ratings" do
    setup do
      expected_bad_order_id = 16

      assignments = %{
        good_one: %Assignment{
          order: %Order{id: 42, unit: %Unit{number: "XYZ"}},
          tech: %Tech{name: "Paul"},
          rating: 4
        },
        good_two: %Assignment{
          order: %Order{id: 15, unit: %Unit{number: "ABC"}},
          tech: %Tech{name: "Ringo"},
          rating: 5
        },
        not_good: %Assignment{
          order_id: expected_bad_order_id,
          order: %Order{id: expected_bad_order_id, unit: %Unit{number: "ZZZ"}},
          tech: %Tech{name: "Ringo"},
          rating: 1
        }
      }

      property = %Property{}
      date_range_today = DateTimeRange.today()
      ~M[assignments, property, date_range_today, expected_bad_order_id]
    end
  end

  describe "Daily WorkOrderViolationsProbe " do
    test "No violations ", ~M[builder, date_range_today] do
      property =
        builder
        |> PropBuilder.get_requirement(:property)

      daily_context = ProbeContext.new([], [], property, date_range_today)

      # When
      daily_context = Daily.report_insight_item(daily_context, WorkOrderViolationsProbe)

      assert daily_context.comments == []
    end

    test "one violation", ~M[builder, date_range_today] do
      property =
        builder
        |> PropBuilder.add_work_order_on_unit(priority: 3)
        |> PropBuilder.get_requirement(:property)

      daily_context = ProbeContext.new([], [], property, date_range_today)
      # When
      daily_context = Daily.report_insight_item(daily_context, WorkOrderViolationsProbe)

      assert daily_context.comments ==
               [
                 "Urgent! There is 1 open City Code violation. Please resolve this as quickly as possible."
               ]
    end

    test "two violations", ~M[builder, date_range_today] do
      property =
        builder
        |> PropBuilder.add_work_order_on_unit(priority: 3)
        |> PropBuilder.add_work_order_on_unit(priority: 3)
        |> PropBuilder.get_requirement(:property)

      daily_context = ProbeContext.new([], [], property, date_range_today)

      # When
      daily_context = Daily.report_insight_item(daily_context, WorkOrderViolationsProbe)

      assert daily_context.comments ==
               [
                 "Urgent! There are 2 open City Code violations. Please resolve these as quickly as possible."
               ]
    end
  end

  describe "calls MakeReadyPercentageProbe" do
    test " no comments ", ~M[builder, date_range_today] do
      property =
        builder
        |> PropBuilder.get_requirement(:property)

      daily_context = ProbeContext.new([], [], property, date_range_today)

      # When
      daily_context =
        Daily.report_insight_item(
          daily_context,
          AppCount.Maintenance.InsightReports.MakeReadyPercentageProbe
        )

      assert daily_context.comments == []
    end

    test "has comments for when it's >80%", ~M[builder, date_range_today] do
      date = Timex.now()

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

      daily_context =
        [unit_tallies: unit_tallies]
        |> ProbeContext.input_map()
        |> ProbeContext.new(property, date_range_today)

      # When
      daily_context =
        Daily.report_insight_item(
          daily_context,
          AppCount.Maintenance.InsightReports.MakeReadyPercentageProbe
        )

      assert daily_context.comments == ["Great job having 100.0% of your units ready!"]
    end

    test "has comments for when it's <80% & there are >= 5 not ready units",
         ~M[builder, date_range_today] do
      date = Timex.now()

      not_ready_card_attrs = [
        completion: nil
      ]

      ready_card_attrs = [
        completion: %{
          "date" => DateTime.to_iso8601(date),
          "name" => "blah"
        }
      ]

      # Make a property with 6 not ready units and 1 ready unit giving it a
      # Make Ready percentage of ~14.2%
      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(not_ready_card_attrs)
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(not_ready_card_attrs)
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(not_ready_card_attrs)
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(not_ready_card_attrs)
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(not_ready_card_attrs)
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(not_ready_card_attrs)
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(ready_card_attrs)
        |> PropBuilder.get_requirement(:property)

      unit_tallies = AppCount.Maintenance.Utils.Cards.ready_and_not_ready_count(property)

      daily_context =
        [unit_tallies: unit_tallies]
        |> ProbeContext.input_map()
        |> ProbeContext.new(property, date_range_today)

      # When
      daily_context =
        Daily.report_insight_item(
          daily_context,
          AppCount.Maintenance.InsightReports.MakeReadyPercentageProbe
        )

      assert daily_context.comments == [
               "Make-Readies need some work here. Please work to get it at least 80%"
             ]
    end

    test "no comments for when there are < 5 units not ready", ~M[builder, date_range_today] do
      date = Timex.now()

      not_ready_card_attrs = [
        completion: nil
      ]

      ready_card_attrs = [
        completion: %{
          "date" => DateTime.to_iso8601(date),
          "name" => "blah"
        }
      ]

      # Make a property with 1 not ready unit and 1 ready unit giving it a
      # Make Ready percentage of 50%
      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(not_ready_card_attrs)
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(ready_card_attrs)
        |> PropBuilder.get_requirement(:property)

      daily_context = ProbeContext.new([], [], property, date_range_today)

      # When
      daily_context =
        Daily.report_insight_item(
          daily_context,
          AppCount.Maintenance.InsightReports.MakeReadyPercentageProbe
        )

      assert daily_context.comments == []
    end
  end

  describe "Daily.make_ready_turnaround_time_comments" do
    test "when averaging < 7 days", ~M[builder, date_range_today] do
      completion_date = Timex.now()

      ready_card_attrs = [
        completion: %{
          "date" => DateTime.to_iso8601(completion_date),
          "name" => "Some Admin"
        },
        move_out_date: completion_date |> Timex.shift(days: -4) |> Timex.to_date()
      ]

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(ready_card_attrs)
        |> PropBuilder.get_requirement(:property)

      daily_context =
        daily_context_with_completed_by_property(
          property,
          date_range_today
        )

      daily_context = Daily.report_insight_item(daily_context, MakeReadyTurnaroundProbe)

      # Dependending on when you run the test, we'll get either 4 or 5 days for
      # turnaround (as we round to the nearest day)
      expected_regex =
        ~r{Phenomenal work on the turnaround time getting units ready! You are currently averaging (4|5) days.}

      assert Enum.any?(daily_context.comments, fn item -> String.match?(item, expected_regex) end)
    end

    test "when averaging > 14 days", ~M[builder, date_range_today] do
      completion_date = Timex.now()

      ready_card_attrs = [
        completion: %{
          "date" => DateTime.to_iso8601(completion_date),
          "name" => "Some Admin"
        },
        move_out_date: completion_date |> Timex.shift(days: -24) |> Timex.to_date()
      ]

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(ready_card_attrs)
        |> PropBuilder.get_requirement(:property)

      daily_context = daily_context_with_completed_by_property(property, date_range_today)

      # When
      daily_context = Daily.report_insight_item(daily_context, MakeReadyTurnaroundProbe)

      # Depending on when you run the test, this will give you either 24 or 25
      # days (as we round to the nearest day)
      expected_regex =
        ~r{Let's keep an eye on how much time it takes to get units ready. Right now we are averaging 3 weeks, (3|4) days. Let's work to bring this down to under 7 days.}

      assert Enum.any?(daily_context.comments, fn item -> String.match?(item, expected_regex) end)
    end

    def daily_context_with_completed_by_property(property, date_range_today) do
      thirty_days_ago_range = DateTimeRange.last30days(date_range_today.from)

      completed_cards =
        PropertyRepo.completed_cards(
          ClientSchema.new("dasmen", property),
          thirty_days_ago_range.from |> DateTime.to_date()
        )

      ProbeContext.input_map(completed_cards: completed_cards)
      |> ProbeContext.new(property, date_range_today)
    end

    test "when averaging between 7 and 14 days", ~M[builder, date_range_today] do
      completion_date = Timex.now()

      ready_card_attrs = [
        completion: %{
          "date" => DateTime.to_iso8601(completion_date),
          "name" => "Some Admin"
        },
        move_out_date: completion_date |> Timex.shift(days: -8) |> Timex.to_date()
      ]

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(ready_card_attrs)
        |> PropBuilder.get_requirement(:property)

      daily_context =
        ProbeContext.input_map()
        |> ProbeContext.new(property, date_range_today)

      # When
      daily_context = Daily.report_insight_item(daily_context, MakeReadyTurnaroundProbe)

      assert daily_context.comments == []
    end

    test "with no make-readies", ~M[builder, date_range_today] do
      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.get_requirement(:property)

      daily_context = ProbeContext.new([], [], property, date_range_today)

      # When
      daily_context = Daily.report_insight_item(daily_context, MakeReadyTurnaroundProbe)

      assert daily_context.comments == []
    end
  end
end
