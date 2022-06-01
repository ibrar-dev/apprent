defmodule AppCount.Jobs.Utils.Jobs do
  alias AppCount.Jobs.Job
  alias AppCount.Jobs.Scheduler
  alias AppCount.Jobs.Schedule
  alias AppCount.Repo
  alias AppCount.Public.Client
  import Ecto.Query

  def list_jobs(schema) do
    from(j in Job, select: map(j, [:id, :schedule, :function, :arguments, :last_run, :next_run]))
    |> Repo.all(prefix: schema)
    |> Enum.map(&Map.put(&1, :schedule, Map.from_struct(&1.schedule)))
  end

  def create_job(params, schema) do
    cs = Job.changeset(%Job{}, params)
    schedule = struct(Schedule, cs.changes.schedule.changes)

    Job.changeset(cs, %{next_run: Scheduler.next_ts(schedule)})
    |> Repo.insert(prefix: schema)
    |> case do
      {:ok, job} ->
        AppCount.Jobs.Server.refresh()
        {:ok, job}

      {:error, error} ->
        {:error, error}
    end
  end

  def update_job(id, params, schema) do
    Repo.get(Job, id, prefix: schema)
    |> Job.changeset(params)
    |> Repo.update(prefix: schema)
    |> case do
      {:ok, job} ->
        set_schedule(job, schema)
        AppCount.Jobs.Server.refresh()

      {:error, e} ->
        {:error, e}
    end
  end

  def delete_job(id, schema) do
    Repo.get(Job, id, prefix: schema)
    |> Repo.delete(prefix: schema)
  end

  def list_pending_jobs() do
    ts =
      Timex.now()
      |> Timex.to_unix()

    from(
      c in Client,
      order_by: [asc: c.client_schema],
      select: c.client_schema
    )
    |> Repo.all()
    |> Enum.reduce([], fn schema, all_jobs ->
      from(
        j in Job,
        where: not is_nil(j.next_run) and j.next_run > ^ts,
        order_by: [asc: j.next_run],
        select: {j.next_run, j.id, ^schema}
      )
      |> Repo.all(prefix: schema)
      |> Enum.reduce(all_jobs, &[&1 | &2])
    end)
  end

  def schedule_all() do
    from(
      c in Client,
      order_by: [asc: c.client_schema],
      select: c.client_schema
    )
    |> Repo.all(prefix: "public")
    |> Enum.each(fn schema ->
      Repo.all(Job, prefix: schema)
      |> Enum.each(fn job ->
        set_schedule(job, schema)
      end)
    end)
  end

  def set_schedule(job, schema) do
    job
    |> Job.changeset(%{next_run: Scheduler.next_ts(job.schedule)})
    |> Repo.update(prefix: schema)
  end
end
