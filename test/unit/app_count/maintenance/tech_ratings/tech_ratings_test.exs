defmodule AppCount.Maintenance.TechRatings.TechRatingsTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.TechRatings.TechRatings
  alias AppCount.Maintenance.TechRepo
  alias AppCount.Maintenance.Tech
  alias AppCount.Support.TechAssignmentsBuilder, as: TechBuilder
  #  assignments: [ %Assignment{order: order},  %Assignment{order: order},]
  setup do
    tech = %Tech{id: 1111, aggregate: true, assignments: []}

    times =
      AppTime.new()
      |> AppTime.plus_to_naive(:now, days: 0)
      |> AppTime.plus_to_naive(:yesterday, days: -1)
      |> AppTime.plus_to_naive(:two_hours_ago, hours: -2)
      |> AppTime.plus_to_naive(:one_hour_ago, hours: -1)
      |> AppTime.times()

    ~M[tech, times]
  end

  describe "new/1" do
    test "no data, zero assignment", ~M[tech] do
      # When
      ratings = TechRatings.new(tech)
      assert ratings.tech_id == tech.id
      assert ratings.completion_count == 0
      assert ratings.avg_completion_time == {0, :hours}
      assert ratings.callback_percent == {0, :basis_points}
      assert ratings.avg_rating == 0
    end
  end

  describe "new/1 avg_completion_time" do
    test "== 24, one assignment", ~M[tech, times] do
      tech =
        tech
        |> TechBuilder.add_assignment(:avg_completion_time, %{
          inserted_at: times.yesterday,
          completed_at: times.now
        })

      # When
      ratings = TechRatings.new(tech)
      assert ratings.completion_count == 1
      assert ratings.avg_completion_time == {24, :hours}
    end

    test "== 12, two assignments", ~M[tech, times] do
      tech =
        tech
        |> TechBuilder.add_assignment(:avg_completion_time, %{
          inserted_at: times.yesterday,
          completed_at: times.now
        })
        |> TechBuilder.add_assignment(:avg_completion_time, %{
          inserted_at: times.one_hour_ago,
          completed_at: times.now
        })

      # When
      ratings = TechRatings.new(tech)
      assert ratings.completion_count == 2
      assert ratings.avg_completion_time == {12, :hours}
    end

    test "== 13, two assignments", ~M[tech, times] do
      tech =
        tech
        |> TechBuilder.add_assignment(:avg_completion_time, %{
          inserted_at: times.yesterday,
          completed_at: times.now
        })
        |> TechBuilder.add_assignment(:avg_completion_time, %{
          inserted_at: times.two_hours_ago,
          completed_at: times.now
        })

      # When
      ratings = TechRatings.new(tech)
      assert ratings.completion_count == 2
      assert ratings.avg_completion_time == {13, :hours}
    end
  end

  describe "new/1 completion_count" do
    test "== 1", ~M[tech] do
      tech = tech |> TechBuilder.add_assignment(:completion_count)

      # When
      ratings = TechRatings.new(tech)
      assert ratings.tech_id == tech.id
      assert ratings.completion_count == 1
    end

    test "== 1, incomplete = 1", ~M[tech] do
      tech =
        tech
        |> TechBuilder.add_assignment(:completion_count)
        |> TechBuilder.add_assignment(:incomplete)

      # When
      ratings = TechRatings.new(tech)
      assert ratings.completion_count == 1
    end

    test "== 100", ~M[tech] do
      tech =
        1..100
        |> Enum.reduce(tech, fn _num, tech ->
          TechBuilder.add_assignment(tech, :completion_count)
        end)

      # When
      ratings = TechRatings.new(tech)
      assert ratings.completion_count == 100
    end
  end

  describe "new/1 callback_percent" do
    test "==  {100, :basis_points},", ~M[tech] do
      tech =
        1..99
        |> Enum.reduce(tech, fn _num, tech ->
          TechBuilder.add_assignment(tech, :completion_count)
        end)
        |> TechBuilder.add_assignment(:callback)

      # When
      ratings = TechRatings.new(tech)
      assert ratings.completion_count == 100
      assert ratings.callback_percent == {100, :basis_points}
    end

    test " ==  {50, :basis_points},", ~M[tech] do
      tech =
        1..199
        |> Enum.reduce(tech, fn _num, tech ->
          TechBuilder.add_assignment(tech, :completion_count)
        end)
        |> TechBuilder.add_assignment(:callback)

      # When
      ratings = TechRatings.new(tech)
      assert ratings.completion_count == 200
      assert ratings.callback_percent == {50, :basis_points}
    end

    test "==  {66, :basis_points},", ~M[tech] do
      tech =
        1..149
        |> Enum.reduce(tech, fn _num, tech ->
          TechBuilder.add_assignment(tech, :completion_count)
        end)
        |> TechBuilder.add_assignment(:callback)

      # When
      ratings = TechRatings.new(tech)
      assert ratings.completion_count == 150
      assert ratings.callback_percent == {66, :basis_points}
    end
  end

  describe "new/1 avg_rating" do
    test "==  5, 100 orders", ~M[tech] do
      tech =
        tech
        |> TechBuilder.add_assignment(:rating, %{rating: 5})

      # When
      ratings = TechRatings.new(tech)
      assert ratings.completion_count == 1
      assert ratings.avg_rating == 5
    end

    test "==  3, 100 orders wider range", ~M[tech] do
      tech =
        1..20
        |> Enum.reduce(tech, fn _num, tech ->
          TechBuilder.add_assignment(tech, :rating, %{rating: 1})
        end)

      tech =
        1..20
        |> Enum.reduce(tech, fn _num, tech ->
          TechBuilder.add_assignment(tech, :rating, %{rating: 2})
        end)

      tech =
        1..20
        |> Enum.reduce(tech, fn _num, tech ->
          TechBuilder.add_assignment(tech, :rating, %{rating: 3})
        end)

      tech =
        1..20
        |> Enum.reduce(tech, fn _num, tech ->
          TechBuilder.add_assignment(tech, :rating, %{rating: 4})
        end)

      tech =
        1..20
        |> Enum.reduce(tech, fn _num, tech ->
          TechBuilder.add_assignment(tech, :rating, %{rating: 5})
        end)

      # When
      ratings = TechRatings.new(tech)
      assert ratings.completion_count == 100
      assert ratings.avg_rating == 3
    end

    test "== 4, skip nils", ~M[tech] do
      tech =
        1..20
        |> Enum.reduce(tech, fn _num, tech ->
          TechBuilder.add_assignment(tech, :rating, %{rating: nil})
        end)

      tech =
        1..20
        |> Enum.reduce(tech, fn _num, tech ->
          TechBuilder.add_assignment(tech, :rating, %{rating: 3})
        end)

      tech =
        1..20
        |> Enum.reduce(tech, fn _num, tech ->
          TechBuilder.add_assignment(tech, :rating, %{rating: 4})
        end)

      tech =
        1..20
        |> Enum.reduce(tech, fn _num, tech ->
          TechBuilder.add_assignment(tech, :rating, %{rating: 5})
        end)

      # When
      ratings = TechRatings.new(tech)
      assert ratings.completion_count == 80
      assert ratings.avg_rating == 4
    end
  end

  describe "tech exists in DB with no data" do
    setup do
      [_builder, tech] =
        PropBuilder.new()
        |> PropBuilder.add_property()
        |> PropBuilder.add_tech()
        |> PropBuilder.get([:tech])

      tech_id = tech.id
      ~M[tech_id]
    end

    test "new/1", ~M[tech_id] do
      # When
      {:ok, tech} = TechRepo.aggregate(tech_id)
      ratings = TechRatings.new(tech)

      assert tech.aggregate
      assert ratings.tech_id == tech_id
    end
  end
end
