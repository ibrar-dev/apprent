defmodule AppCount.Maintenance.TechRatings.TechPointsTest do
  use AppCount.Case
  alias AppCount.Maintenance.TechRatings.TechRatings
  alias AppCount.Maintenance.TechRatings.TechPoints

  setup do
    ratings = %TechRatings{
      tech_id: 0,
      avg_completion_time: {49, :hours},
      callback_percent: {200, :basis_points},
      avg_rating: 0,
      completion_count: 0
    }

    expected_points = %TechPoints{
      tech_id: 0,
      avg_completion_time: 0,
      callback_percent: 0,
      avg_rating: 0,
      completion_count: 0
    }

    ~M[ratings, expected_points]
  end

  test "zero points", ~M[ratings, expected_points] do
    # When
    points = TechPoints.points(ratings)
    assert points == expected_points
  end

  describe "avg_completion_time" do
    test " < 24 :hours", ~M[ratings, expected_points] do
      ratings = %{ratings | avg_completion_time: {23, :hours}}
      expected_points = %{expected_points | avg_completion_time: 10}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test " < 48 :hours", ~M[ratings, expected_points] do
      ratings = %{ratings | avg_completion_time: {47, :hours}}
      expected_points = %{expected_points | avg_completion_time: 5}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test " 48+ :hours", ~M[ratings, expected_points] do
      ratings = %{ratings | avg_completion_time: {48, :hours}}
      expected_points = %{expected_points | avg_completion_time: 0}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end
  end

  describe "callbacks" do
    test " < 1 :percent", ~M[ratings, expected_points] do
      ratings = %{ratings | callback_percent: {99, :basis_points}}
      expected_points = %{expected_points | callback_percent: 25}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test " < 2 :percent", ~M[ratings, expected_points] do
      ratings = %{ratings | callback_percent: {199, :basis_points}}
      expected_points = %{expected_points | callback_percent: 15}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test " == 2 :percent", ~M[ratings, expected_points] do
      ratings = %{ratings | callback_percent: {200, :basis_points}}
      expected_points = %{expected_points | callback_percent: 0}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end
  end

  describe "avg_rating" do
    test "1 ", ~M[ratings, expected_points] do
      ratings = %{ratings | avg_rating: 1}
      expected_points = %{expected_points | avg_rating: 0}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test "2 ", ~M[ratings, expected_points] do
      ratings = %{ratings | avg_rating: 2}
      expected_points = %{expected_points | avg_rating: 0}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test "3 ", ~M[ratings, expected_points] do
      ratings = %{ratings | avg_rating: 3}
      expected_points = %{expected_points | avg_rating: 10}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test "4 ", ~M[ratings, expected_points] do
      ratings = %{ratings | avg_rating: 4}
      expected_points = %{expected_points | avg_rating: 25}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test "5 ", ~M[ratings, expected_points] do
      ratings = %{ratings | avg_rating: 5}
      expected_points = %{expected_points | avg_rating: 25}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end
  end

  describe "completion_count" do
    test "0 ", ~M[ratings, expected_points] do
      ratings = %{ratings | completion_count: 0}
      expected_points = %{expected_points | completion_count: 0}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test "14", ~M[ratings, expected_points] do
      ratings = %{ratings | completion_count: 14}
      expected_points = %{expected_points | completion_count: 0}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test "15", ~M[ratings, expected_points] do
      ratings = %{ratings | completion_count: 15}
      expected_points = %{expected_points | completion_count: 20}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test "75", ~M[ratings, expected_points] do
      ratings = %{ratings | completion_count: 75}
      expected_points = %{expected_points | completion_count: 20}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test "76", ~M[ratings, expected_points] do
      ratings = %{ratings | completion_count: 76}
      expected_points = %{expected_points | completion_count: 25}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test "150", ~M[ratings, expected_points] do
      ratings = %{ratings | completion_count: 150}
      expected_points = %{expected_points | completion_count: 25}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test "151", ~M[ratings, expected_points] do
      ratings = %{ratings | completion_count: 151}
      expected_points = %{expected_points | completion_count: 30}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test "200", ~M[ratings, expected_points] do
      ratings = %{ratings | completion_count: 200}
      expected_points = %{expected_points | completion_count: 30}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test "201", ~M[ratings, expected_points] do
      ratings = %{ratings | completion_count: 201}
      expected_points = %{expected_points | completion_count: 35}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test "250", ~M[ratings, expected_points] do
      ratings = %{ratings | completion_count: 250}
      expected_points = %{expected_points | completion_count: 35}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end

    test "251", ~M[ratings, expected_points] do
      ratings = %{ratings | completion_count: 251}
      expected_points = %{expected_points | completion_count: 40}
      # When
      points = TechPoints.points(ratings)
      assert points == expected_points
    end
  end

  describe "sum" do
    test "zero" do
      points = %TechPoints{
        tech_id: 0,
        avg_completion_time: 0,
        callback_percent: 0,
        avg_rating: 0,
        completion_count: 0
      }

      result = TechPoints.sum(points)
      assert result == 0
    end

    test "one each" do
      points = %TechPoints{
        tech_id: 1,
        avg_completion_time: 1,
        callback_percent: 1,
        avg_rating: 1,
        completion_count: 1
      }

      result = TechPoints.sum(points)
      assert result == 5
    end
  end
end
