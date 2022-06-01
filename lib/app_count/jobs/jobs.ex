defmodule AppCount.Jobs do
  alias AppCount.Jobs.Utils.Jobs
  alias AppCount.Jobs.Utils.Migrations
  alias AppCount.Jobs.Utils.Tasks

  def list_jobs(schema), do: Jobs.list_jobs(schema)
  def create_job(params, schema), do: Jobs.create_job(params, schema)
  def update_job(id, params, schema), do: Jobs.update_job(id, params, schema)
  def delete_job(id, schema), do: Jobs.delete_job(id, schema)
  def list_pending_jobs(), do: Jobs.list_pending_jobs()
  def schedule_all(), do: Jobs.schedule_all()
  def set_schedule(job, schema), do: Jobs.set_schedule(job, schema)

  def list_migrations(), do: Migrations.list_migrations()
  def create_migration(params), do: Migrations.create_migration(params)
  def update_migration(id, params), do: Migrations.update_migration(id, params)
  def delete_migration(id), do: Migrations.delete_migration(id)

  def insert_task(params, client_schema), do: Tasks.insert_task(params, client_schema)
  def list_tasks(params, client_schema), do: Tasks.list_tasks(params, client_schema)
end
