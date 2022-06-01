defmodule AppCount.Tasks.Workers.MaintenanceOrders do
  import Ecto.Query
  alias AppCount.Maintenance
  alias AppCount.Maintenance.RecurringOrder
  alias AppCount.Jobs.Scheduler
  alias AppCount.Repo
  use AppCount.Tasks.Worker, "Maintenance Orders"
  alias AppCount.Core.ClientSchema

  @impl AppCount.Tasks.Worker
  # TODO:SCHEMA fetch all client and run
  def perform(schema \\ "dasmen") do
    now =
      AppCount.current_time()
      |> Timex.to_unix()

    from(
      r in RecurringOrder,
      where: r.next_run <= ^now
    )
    |> Repo.all(prefix: schema)
    |> Enum.each(&process/1)
  end

  def process(order) do
    # TODO:SCHEMA redo this(needed to reduce pr size)
    schema = "dasmen"

    params =
      order.params
      |> Map.merge(%{"admin_id" => order.admin_id, "property_id" => order.property_id})

    Maintenance.create_order(ClientSchema.new(schema, params))

    case Scheduler.next_ts(order.schedule) do
      nil ->
        Repo.delete(order, prefix: schema)

      ts ->
        order
        |> RecurringOrder.changeset(%{next_run: ts, last_run: order.next_run})
        |> Repo.update(prefix: schema)
    end
  end
end
