defmodule AppCount.Jobs.Utils.Tasks do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Jobs.Task

  def list_tasks(%{"start_date" => start, "end_date" => end_time, "description" => desc}, schema) do
    like_query = "%#{desc}%"

    from(
      t in Task,
      where: t.start_time >= ^parse_date(start),
      where: t.start_time <= ^parse_date(end_time),
      where: ilike(t.description, ^like_query),
      select:
        map(t, [:id, :arguments, :start_time, :end_time, :logs, :error, :description, :success]),
      order_by: [
        desc: t.start_time
      ]
    )
    |> Repo.all(prefix: schema)
  end

  def insert_task(params, client_schema) do
    %Task{}
    |> Task.changeset(params)
    |> Repo.insert!(prefix: client_schema)
  end

  defp parse_date(date_string) do
    Timex.parse!(date_string, "{YYYY}-{0M}-{D}")
  end
end
