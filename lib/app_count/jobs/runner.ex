defmodule AppCount.Jobs.Runner do
  alias AppCount.Jobs.Job
  alias AppCount.Jobs.Scheduler
  alias AppCount.Jobs.Server
  alias AppCount.Repo

  def run(job_id, schema) do
    job = Repo.get(Job, job_id, prefix: schema)

    if job do
      do_run(job, schema)
    end
  end

  def do_run(%Job{} = job, client_schema) do
    args = job.arguments ++ [client_schema]
    module = Module.concat(["AppCount.Tasks.Workers.#{job.function}"])
    func = Function.capture(module, :perform, length(args))
    AppCount.Tasks.Enqueue.enqueue(module.desc, func, args, client_schema)

    AppCount.Core.Tasker.start(fn ->
      schedule(job, client_schema)
      Server.refresh()
    end)

    :ok
  end

  def schedule(job, schema) do
    # Have the job updated in the right schema.
    job
    |> Job.changeset(%{next_run: Scheduler.next_ts(job.schedule), last_run: job.next_run})
    |> Repo.update(prefix: schema)
  end
end
