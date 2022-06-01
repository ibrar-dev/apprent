defmodule AppCount.Maintenance.TechRepo do
  alias AppCount.Maintenance.Job
  alias AppCount.Maintenance.Skill

  use AppCount.Core.GenericRepo,
    schema: AppCount.Maintenance.Tech,
    preloads: [jobs: [:property], skills: [], assignments: [:order]]

  def update(%Tech{id: tech_id} = tech, attrs) do
    changeset =
      tech
      |> @schema.changeset(attrs)
      |> unique_tech_name?(tech_id)

    if changeset.valid? do
      Ecto.Multi.new()
      |> Ecto.Multi.update(:tech, changeset)
      |> skill_changes(tech_id, Map.get(attrs, "category_ids"))
      |> job_changes(tech_id, Map.get(attrs, "property_ids"))
      |> Repo.transaction()
      |> case do
        {:ok, %{tech: tech}} -> {:ok, tech}
        error -> error
      end
    else
      {:error, changeset}
    end
  end

  def add_skill(%Tech{id: tech_id}, %AppCount.Maintenance.Category{id: category_id}) do
    attrs = %{tech_id: tech_id, category_id: category_id}

    changeset =
      %AppCount.Maintenance.Skill{}
      |> AppCount.Maintenance.Skill.changeset(attrs)

    if changeset.valid? do
      Repo.insert(changeset)
    else
      {:error, changeset}
    end
  end

  def update!(%Tech{id: tech_id} = tech, attrs) do
    changeset =
      tech
      |> @schema.changeset(attrs)
      |> unique_tech_name?(tech_id)

    Repo.update!(changeset)
  end

  def insert(attrs) when is_map(attrs) do
    no_tech_id = 0

    changeset =
      %Tech{}
      |> @schema.changeset(attrs)
      |> unique_tech_name?(no_tech_id)

    if changeset.valid? do
      Repo.insert(changeset)
    else
      {:error, changeset}
    end
  end

  def get_tech_index_info(tech_id) do
    get_aggregate(tech_id)
  end

  def get_by_pass_code(pass_code) do
    Repo.get_by(@schema, pass_code: pass_code)
  end

  def get_by_identifier(identifier) do
    Repo.get_by(@schema, identifier: identifier)
  end

  def for_property(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_id
      }) do
    from(
      j in Job,
      where: j.property_id == ^property_id,
      preload: [tech: [:skills, :assignments]]
    )
    |> Repo.all(prefix: client_schema)
    |> Enum.map(fn %Job{tech: tech} -> tech end)
    |> Enum.uniq()
    |> Enum.filter(fn %Tech{} = tech -> tech.active end)
  end

  def unit_lease_status(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: property},
        date_range
      ) do
    AppCount.Reports.Queries.UnitStatus.full_unit_status(
      property.id,
      date_range.to
      |> DateTime.to_date()
    )
    |> Repo.all(prefix: client_schema)
  end

  # --- Private  -----------------------------

  defp duplicate_exists?(current_tech_id, tech_name) when is_integer(current_tech_id) do
    from(
      t in @schema,
      where: t.id != ^current_tech_id,
      where: t.name == ^tech_name,
      where: t.active == true
    )
    |> Repo.exists?()
  end

  defp unique_tech_name?(%{changes: %{name: name}} = changeset, current_tech_id) do
    validate_unique(changeset, name, current_tech_id)
  end

  defp unique_tech_name?(%{data: %{name: name}} = changeset, current_tech_id) do
    validate_unique(changeset, name, current_tech_id)
  end

  defp validate_unique(changeset, name, current_tech_id) do
    duplicate_found = duplicate_exists?(current_tech_id, name)

    if duplicate_found do
      changeset
      |> Ecto.Changeset.add_error(:name, "A Tech named #{name} already exists")
    else
      changeset
    end
  end

  defp skill_changes(multi, _tech_id, nil), do: multi

  defp skill_changes(multi, tech_id, category_ids) do
    to_delete =
      from(s in Skill, where: s.tech_id == ^tech_id and s.category_id not in ^category_ids)

    Enum.reduce(
      category_ids,
      multi,
      fn category_id, multi ->
        Ecto.Multi.insert(
          multi,
          "skill_#{category_id}",
          Skill.changeset(%Skill{}, %{tech_id: tech_id, category_id: category_id}),
          on_conflict: :nothing
        )
      end
    )
    |> Ecto.Multi.delete_all(:removed_skills, to_delete)
  end

  defp job_changes(multi, _tech_id, nil), do: multi

  defp job_changes(multi, _tech_id, "clear"), do: multi

  defp job_changes(multi, tech_id, property_ids) when is_list(property_ids) do
    to_delete =
      from(j in Job, where: j.tech_id == ^tech_id and j.property_id not in ^property_ids)

    Enum.reduce(
      property_ids,
      multi,
      fn property_id, multi ->
        cs = Job.changeset(%Job{}, %{tech_id: tech_id, property_id: property_id})
        Ecto.Multi.insert(multi, "job_#{property_id}", cs, on_conflict: :nothing)
      end
    )
    |> Ecto.Multi.delete_all(:removed_jobs, to_delete)
  end
end
