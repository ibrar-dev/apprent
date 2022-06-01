defmodule AppCount.Maintenance.InsightReports.MakeReadyTurnaroundProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Properties.PropertyRepo
  alias AppCount.Maintenance.InsightReports.MakeReadyTurnaroundProbe
  alias AppCount.Core.ClientSchema

  describe "reading/3" do
    setup do
      start_date = Timex.now() |> Timex.shift(days: -30) |> Timex.to_date()

      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()

      ~M[start_date, builder]
    end

    test "a property with 0 cards for an average make ready time of ZERO",
         ~M[start_date, builder] do
      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.get_requirement(:property)

      completed_cards =
        PropertyRepo.completed_cards(ClientSchema.new("dasmen", property), start_date)

      probe_context = %ProbeContext{input: %{completed_cards: completed_cards}}
      # When
      reading = MakeReadyTurnaroundProbe.reading(probe_context)

      expected_result = 0

      assert expected_result == reading.value
    end
  end

  describe "call/3" do
    setup do
      start_date = Timex.now() |> Timex.shift(days: -30) |> Timex.to_date()

      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()

      ~M[start_date, builder]
    end

    test "a property with 1 cards for an average make ready time of nearly 3 days (259,200 - 1 seconds)",
         ~M[start_date, builder] do
      actual_move_out = Timex.now() |> Timex.shift(days: -6) |> Timex.to_date()
      made_ready_by = Timex.now() |> Timex.shift(days: -4) |> Timex.end_of_day()

      card_attrs = [
        move_out_date: actual_move_out,
        completion: %{
          "date" => DateTime.to_iso8601(made_ready_by),
          "name" => "blah"
        }
      ]

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(card_attrs)
        |> PropBuilder.get_requirement(:property)

      completed_cards =
        PropertyRepo.completed_cards(ClientSchema.new("dasmen", property), start_date)

      # When
      result = MakeReadyTurnaroundProbe.call(completed_cards)

      # 3 days to seconds with one second subtracted to account for Timex.end_of_day
      expected_result = 3 * 24 * 60 * 60 - 1

      assert expected_result == result
    end

    test "a property with 2 cards for an average make ready time of nearly 6 days (518400 - 1 seconds)",
         ~M[start_date, builder] do
      first_actual_move_out = Timex.now() |> Timex.shift(days: -6) |> Timex.to_date()
      first_made_ready_by = Timex.now() |> Timex.shift(days: -3) |> Timex.end_of_day()

      second_actual_move_out = Timex.now() |> Timex.shift(days: -10) |> Timex.to_date()
      second_made_ready_by = Timex.now() |> Timex.shift(days: -3) |> Timex.end_of_day()

      first_card_attrs = [
        move_out_date: first_actual_move_out,
        completion: %{
          "date" => DateTime.to_iso8601(first_made_ready_by),
          "name" => "blah"
        }
      ]

      second_card_attrs = [
        move_out_date: second_actual_move_out,
        completion: %{
          "date" => DateTime.to_iso8601(second_made_ready_by),
          "name" => "blah"
        }
      ]

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(first_card_attrs)
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(second_card_attrs)
        |> PropBuilder.get_requirement(:property)

      completed_cards =
        PropertyRepo.completed_cards(ClientSchema.new("dasmen", property), start_date)

      # When
      result = MakeReadyTurnaroundProbe.call(completed_cards)

      # 3 days to seconds with one second subtracted to account for Timex.end_of_day
      expected_result = 6 * 24 * 60 * 60 - 1

      assert expected_result == result
    end

    test "a property with 2 cards with one being out of date. It returns an average make ready time of nearly 8 days",
         ~M[start_date, builder] do
      first_actual_move_out = Timex.now() |> Timex.shift(days: -36) |> Timex.to_date()
      first_made_ready_by = Timex.now() |> Timex.shift(days: -33) |> Timex.end_of_day()

      second_actual_move_out = Timex.now() |> Timex.shift(days: -10) |> Timex.to_date()
      second_made_ready_by = Timex.now() |> Timex.shift(days: -3) |> Timex.end_of_day()

      first_card_attrs = [
        move_out_date: first_actual_move_out,
        completion: %{
          "date" => DateTime.to_iso8601(first_made_ready_by),
          "name" => "blah"
        }
      ]

      second_card_attrs = [
        move_out_date: second_actual_move_out,
        completion: %{
          "date" => DateTime.to_iso8601(second_made_ready_by),
          "name" => "blah"
        }
      ]

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(first_card_attrs)
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(second_card_attrs)
        |> PropBuilder.get_requirement(:property)

      completed_cards =
        PropertyRepo.completed_cards(ClientSchema.new("dasmen", property), start_date)

      # When
      result = MakeReadyTurnaroundProbe.call(completed_cards)

      # 3 days to seconds with one second subtracted to account for Timex.end_of_day
      expected_result = 8 * 24 * 60 * 60 - 1

      assert expected_result == result
    end
  end
end
