defmodule AppCount.Maintenance.TechRecommendBoundary do
  @moduledoc """
  Boundary
  """
  alias AppCount.Maintenance.OrderRepo
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.TechRepo
  alias AppCount.Maintenance.Skill
  alias AppCount.Maintenance.Tech
  alias AppCount.Maintenance.TechRatings.TechRatings
  alias AppCount.Maintenance.TechRatings.TechPoints
  alias AppCount.Core.ClientSchema

  def recommend(work_order_id) when is_number(work_order_id) do
    OrderRepo.get(work_order_id, [:category], [])
    |> recommend()
  end

  # Work order not found
  def recommend(nil) do
    []
  end

  def recommend(%Order{category: category} = order) do
    # TODO:SCHEMA remove this later
    all_techs = TechRepo.for_property(ClientSchema.new("dasmen", order.property_id))

    skilled_techs = techs_with_match_skills(all_techs, category.id)
    two_most_available = two_most_available(skilled_techs)
    two_most_skilled = two_most_skilled(skilled_techs)
    (two_most_available ++ two_most_skilled) |> Enum.uniq()
  end

  def two_most_skilled(skilled_techs, boundary \\ __MODULE__)
      when is_list(skilled_techs) do
    skilled_techs
    |> boundary.points_for_all()
    |> sort_by_points()
    |> Enum.map(fn {_points, tech} ->
      tech
    end)
    |> Enum.take(2)
  end

  def sort_by_points(ratings_and_techs) when is_list(ratings_and_techs) do
    ratings_and_techs |> Enum.sort(fn {one, _tech_one}, {two, _tech_two} -> one < two end)
  end

  def points_for_all(techs, boundary \\ __MODULE__) do
    techs
    |> Enum.map(fn tech ->
      points = boundary.skill_points(tech)
      {points, tech}
    end)
  end

  def skill_points(%Tech{assignments: assignments} = tech) when is_list(assignments) do
    tech
    |> TechRatings.new()
    |> TechPoints.points()
    |> TechPoints.sum()
  end

  defp techs_with_match_skills(techs, work_order_category_id)
       when is_integer(work_order_category_id) do
    techs
    |> Enum.filter(fn tech ->
      tech.skills
      |> Enum.any?(fn %Skill{category_id: tech_category_id} ->
        tech_category_id == work_order_category_id
      end)
    end)
  end

  def two_most_available(techs) do
    techs
    |> Enum.sort(fn one, two ->
      Tech.pending_count(one) > Tech.pending_count(two)
    end)
    |> Enum.take(2)
  end
end
