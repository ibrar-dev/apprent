defmodule AppCount.Maintenance.Utils.RecurringOrders do
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Maintenance.RecurringOrder
  import Ecto.Query
  alias AppCount.Core.ClientSchema

  def list_recurring_orders(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin
      }) do
    from(
      r in RecurringOrder,
      where: r.property_id in ^Admins.property_ids_for(ClientSchema.new("dasmen", admin)),
      select: map(r, [:id, :property_id, :name, :params, :schedule, :admin_id]),
      order_by: [asc: r.name]
    )
    |> Repo.all(prefix: client_schema)
  end

  def create_recurring_order(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    %RecurringOrder{}
    |> RecurringOrder.changeset(params)
    |> Repo.insert(prefix: client_schema)
    |> case do
      {:ok, r} -> schedule_next(ClientSchema.new(client_schema, r))
      e -> e
    end
  end

  def update_recurring_order(id, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    Repo.get(RecurringOrder, id, prefix: client_schema)
    |> RecurringOrder.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def delete_recurring_order(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: id
      }) do
    Repo.get(RecurringOrder, id, prefix: client_schema)
    |> Repo.delete(prefix: client_schema)
  end

  def schedule_next(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: order
      }) do
    order
    |> RecurringOrder.changeset(%{next_run: AppCount.Jobs.Scheduler.next_ts(order.schedule)})
    |> Repo.update(prefix: client_schema)
  end
end
