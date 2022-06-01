defmodule AppCount.Maintenance.Utils.Queries.V1.Techs do
  import Ecto.Query
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Category
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.Skill
  alias AppCount.Maintenance.Tech
  alias AppCount.Maintenance.TechRepo
  alias AppCount.Properties.Property

  # Front-End needs:
  # 1. Tech :id, :profile pic, : name, properties, inserted_at, avg rating,
  # total completed, total assigned, total withdrawn, totall callback, skills, role, active or not active
  def list_techs(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin
      }) do
    base_query(admin)
    |> AppCount.Repo.all(prefix: client_schema)
    |> Enum.map(&compute_metrics(&1))
    |> Enum.map(&Map.delete(&1, :assignments))
    |> Enum.map(&needed_data(&1))
  end

  def get_tech(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        tech_id
      ) do
    from(
      t in base_query(admin),
      where: t.id == ^tech_id,
      preload: [assignments: [order: :property], skills: [category: :parent]]
    )
    |> AppCount.Repo.one(prefix: client_schema)
    |> compute_metrics()
    |> compute_average_completion_time()
    |> recent_activity()
    |> top_skills()
  end

  def show_tech(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        tech_id
      ) do
    get_tech(
      %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin
      },
      tech_id
    )
    |> detail_data()
  end

  def update_tech(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        tech_id,
        attributes
      ) do
    get_tech(
      %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin
      },
      tech_id
    )
    |> TechRepo.update(attributes)
  end

  defp base_query(admin) do
    from(
      techs in Tech,
      left_join: jobs in assoc(techs, :jobs),
      distinct: techs.id,
      where: jobs.property_id in ^admin.property_ids,
      preload: [:assignments, jobs: [:property]]
    )
  end

  defp compute_metrics(%Tech{assignments: assignments} = tech) do
    initial_acc = %{
      rating: [],
      assigned: 0,
      completed: 0,
      withdrawn: 0,
      callbacks: 0,
      tech_score: :rand.uniform(100)
    }

    metrics =
      assignments
      |> Enum.reduce(initial_acc, &reduce_assignments(&1, &2))
      |> avg_ratings()

    tech
    |> Map.put(:metrics, metrics)
  end

  defp reduce_assignments(%Assignment{} = assignment, metrics) do
    metrics
    |> increment_status(assignment)
    |> determine_rating(assignment)
  end

  defp increment_status(metrics, %Assignment{status: status}) do
    Map.update(metrics, determine_status(status), 1, &(&1 + 1))
  end

  defp determine_status("on_hold"), do: :assigned
  defp determine_status("in_progress"), do: :assigned
  defp determine_status("rejected"), do: :withdrawn
  defp determine_status("callback"), do: :callbacks
  defp determine_status(status), do: String.to_atom(status)

  defp determine_rating(acc, %{rating: rating}) when is_nil(rating), do: acc

  defp determine_rating(%{rating: acc_rating} = metrics, %{rating: rating}) do
    Map.merge(metrics, %{rating: acc_rating ++ [rating]})
  end

  defp avg_ratings(metrics) do
    Map.update!(metrics, :rating, &average(&1))
  end

  defp compute_average_completion_time(%Tech{assignments: assignments} = tech) do
    completion_times =
      assignments
      |> Enum.filter(&Assignment.completed?(&1))
      |> Enum.map(&completion_time(&1))

    Map.put(tech, :average_completion_time, average(completion_times))
  end

  defp completion_time(%Assignment{completed_at: completed_at, inserted_at: inserted_at}) do
    NaiveDateTime.diff(completed_at, inserted_at)
  end

  defp recent_activity(%Tech{} = tech) do
    Map.put(tech, :recent_activity, [])
  end

  defp top_skills(%Tech{} = tech) do
    records =
      Enum.map(tech.skills, fn skill ->
        %{
          name: skill.category.name,
          icon: "",
          score: :rand.uniform(100)
        }
      end)

    Map.put(tech, :top_skills, records)
  end

  defp average(values) do
    if Enum.empty?(values) do
      0
    else
      Enum.sum(values) / Enum.count(values)
    end
  end

  # Index fields
  def needed_data(%Tech{} = tech) do
    %{
      active: tech.active,
      id: tech.id,
      inserted_at: tech.inserted_at,
      metrics: tech.metrics,
      name: tech.name
    }
  end

  # Show fields
  def detail_data(%Tech{} = tech) do
    tech
    |> needed_data()
    |> Map.merge(%{
      active: tech.active,
      average_completion_time: tech.average_completion_time,
      assignments: Enum.map(tech.assignments, &detail_data(&1)),
      can_edit: tech.can_edit,
      phone_number: tech.phone_number,
      email: tech.email,
      top_skills: tech.top_skills,
      require_image: tech.require_image,
      skills: Enum.map(tech.skills, &detail_data(&1))
    })
  end

  def detail_data(%Skill{} = skill) do
    %{
      id: skill.id,
      category: detail_data(skill.category)
    }
  end

  def detail_data(%Category{} = category) do
    %{
      id: category.id,
      name: category.name,
      parent: detail_data(category.parent)
    }
  end

  def detail_data(%Assignment{} = assignment) do
    %{
      completed_at: assignment.completed_at,
      inserted_at: assignment.inserted_at,
      order: detail_data(assignment.order),
      status: assignment.status
    }
  end

  def detail_data(%Order{} = order) do
    %{
      property: detail_data(order.property)
    }
  end

  def detail_data(%Property{} = property) do
    %{
      name: property.name
    }
  end

  def detail_data(_record) do
    %{}
  end
end
