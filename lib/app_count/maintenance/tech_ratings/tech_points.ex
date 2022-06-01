defmodule AppCount.Maintenance.TechRatings.TechPoints do
  @moduledoc """
  """

  alias AppCount.Maintenance.TechRatings.TechPoints

  defstruct tech_id: 0,
            avg_completion_time: 0,
            callback_percent: 0,
            avg_rating: 0,
            completion_count: 0

  def points(%{
        tech_id: tech_id,
        avg_completion_time: avg_completion_time,
        callback_percent: callback_percent,
        avg_rating: avg_rating,
        completion_count: completion_count
      }) do
    %TechPoints{tech_id: tech_id}
    |> calc_avg_completion_time(avg_completion_time)
    |> calc_callback_percent(callback_percent)
    |> calc_avg_rating(avg_rating)
    |> calc_completion_count(completion_count)
  end

  def sum(%TechPoints{
        tech_id: tech_id,
        avg_completion_time: avg_completion_time,
        callback_percent: callback_percent,
        avg_rating: avg_rating,
        completion_count: completion_count
      }) do
    tech_id +
      avg_completion_time +
      callback_percent +
      avg_rating +
      completion_count
  end

  def calc_avg_completion_time(%TechPoints{} = tech_points, {avg_completion_hours, :hours}) do
    points =
      cond do
        avg_completion_hours < 24 -> 10
        avg_completion_hours < 48 -> 5
        true -> 0
      end

    %{tech_points | avg_completion_time: points}
  end

  def calc_callback_percent(%TechPoints{} = tech_points, {callback_basis_points, :basis_points}) do
    points =
      cond do
        callback_basis_points < 100 -> 25
        callback_basis_points < 200 -> 15
        true -> 0
      end

    %{tech_points | callback_percent: points}
  end

  def calc_avg_rating(%TechPoints{} = tech_points, avg_rating) do
    points =
      cond do
        avg_rating >= 4 -> 25
        avg_rating == 3 -> 10
        true -> 0
      end

    %{tech_points | avg_rating: points}
  end

  def calc_completion_count(%TechPoints{} = tech_points, completion_count) do
    points =
      cond do
        completion_count > 250 -> 40
        completion_count > 200 -> 35
        completion_count > 150 -> 30
        completion_count > 75 -> 25
        completion_count >= 15 -> 20
        true -> 0
      end

    %{tech_points | completion_count: points}
  end
end
