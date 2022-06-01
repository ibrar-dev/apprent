defmodule AppCount.Maintenance.TechRatings.TechRatings do
  @moduledoc """
  """
  alias __MODULE__
  alias AppCount.Maintenance.Tech
  alias AppCount.Maintenance.Assignment

  defstruct tech_id: 0,
            avg_completion_time: {0, :hours},
            callback_percent: {0, :basis_points},
            avg_rating: 0,
            completion_count: 0

  # Note: Tech aggregate has preloads:
  # [jobs: [:property], skills: [], assignments: [:order]]
  def new(%Tech{} = tech) do
    {%TechRatings{tech_id: tech.id}, tech}
    |> fill_completion_count()
    |> fill_callback_percent()
    |> fill_avg_rating()
    |> fill_avg_completion_time()
    |> tech_rating()
  end

  def tech_rating({%TechRatings{} = tech_rating, _tech}) do
    tech_rating
  end

  def fill_avg_completion_time({%TechRatings{completion_count: 0} = tech_rating, tech}) do
    tech_rating = %{tech_rating | avg_completion_time: {0, :hours}}
    {tech_rating, tech}
  end

  def fill_avg_completion_time(
        {%TechRatings{completion_count: completion_count} = tech_rating, tech}
      ) do
    total_hours =
      tech.assignments
      |> Enum.reduce(0, fn assignment, acc -> completion_hours(assignment) + acc end)

    avg_completion_time = safe_divide(total_hours, completion_count)

    tech_rating = %{tech_rating | avg_completion_time: {avg_completion_time, :hours}}
    {tech_rating, tech}
  end

  defp completion_hours(assignment) do
    result = Assignment.completion_hours(assignment)

    if result == :incomplete do
      0
    else
      result
    end
  end

  def fill_callback_percent(
        {%TechRatings{completion_count: completion_count} = tech_rating, tech}
      ) do
    callback_assignments =
      tech.assignments
      |> Enum.filter(fn assignment -> Assignment.callback?(assignment) end)

    callback_count = length(callback_assignments)

    callback_ratio = safe_basis_divide(callback_count, completion_count)
    tech_rating = %{tech_rating | callback_percent: {callback_ratio, :basis_points}}
    {tech_rating, tech}
  end

  def fill_completion_count({%TechRatings{} = tech_rating, tech}) do
    completed_assignments =
      tech.assignments
      |> Enum.filter(fn assignment -> Assignment.completed?(assignment) end)

    completion_count = length(completed_assignments)
    tech_rating = %{tech_rating | completion_count: completion_count}
    {tech_rating, tech}
  end

  def fill_avg_rating({%TechRatings{} = tech_rating, tech}) do
    ratings =
      tech.assignments
      |> Enum.reject(fn %{rating: rating} -> is_nil(rating) end)

    sum_ratings =
      ratings
      |> Enum.reduce(0, fn %{rating: rating}, acc -> acc + rating end)

    count = length(ratings)

    avg_rating = safe_divide(sum_ratings, count)

    tech_rating = %{tech_rating | avg_rating: avg_rating}
    {tech_rating, tech}
  end

  # -------- private
  defp safe_divide(_callback_count, 0) do
    0
  end

  defp safe_divide(numerator, denominator) do
    Integer.floor_div(numerator, denominator)
  end

  defp safe_basis_divide(_callback_count, 0) do
    0
  end

  defp safe_basis_divide(callback_count, completion_count) do
    basis_points_modifier = 100
    percent_modifier = 100
    numerator = callback_count * percent_modifier * basis_points_modifier
    denominator = completion_count
    Integer.floor_div(numerator, denominator)
  end
end
