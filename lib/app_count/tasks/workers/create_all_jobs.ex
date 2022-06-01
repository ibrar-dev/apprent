defmodule AppCount.Tasks.Workers.CreateAllJobs do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Properties.Property
  alias AppCount.Maintenance.OpenHistory
  require Logger
  use AppCount.Tasks.Worker, "Generate Open Work Order Statistic"

  @impl AppCount.Tasks.Worker
  def perform(schema \\ "dasmen") do
    from(
      p in Property,
      join: s in assoc(p, :setting),
      where: s.active,
      select: p.id,
      order_by: [asc: :id]
    )
    |> Repo.all(prefix: schema)
    |> Enum.each(fn x -> save_open(x, schema) end)
  end

  defp create_record(params, schema) do
    %OpenHistory{}
    |> OpenHistory.changeset(params)
    |> Repo.insert(prefix: schema)
  end

  defp save_open(property_id, schema) do
    total = find_open(property_id, schema)
    Logger.info("#{property_id}:#{total}", label: "SAVE OPEN")
    create_record(%{property_id: property_id, open: total}, schema)
  end

  def find_open(property_id, schema) do
    a = Repo.get(AppCount.Admins.Admin, 389)
    start_date = "2020-06-01"

    end_date =
      AppCount.current_date()
      |> Timex.format!("%Y-%m-%d", :strftime)

    %{unassigned: unassigned, assigned: assigned} =
      AppCount.Maintenance.list_orders_new(
        a,
        "#{start_date},#{end_date}",
        AppCount.Core.ClientSchema.new(schema, [property_id])
      )

    length(unassigned) + length(assigned)
  end
end
