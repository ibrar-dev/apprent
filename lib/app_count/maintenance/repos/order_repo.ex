defmodule AppCount.Maintenance.OrderRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Maintenance.Order,
    preloads: [category: [:parent], tenant: [], notes: [], assignments: [], property: []]

  alias AppCount.Maintenance.Order
  # add these preloads in the future as needed:
  # belongs_to(:unit, AppCount.Properties.Unit)
  # belongs_to(:card_item, AppCount.Maintenance.CardItem)
  # has_many(:offers, AppCount.Maintenance.Offer)
  # has_many(:parts, AppCount.Maintenance.Part)

  def currently_open(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_id
      }) do
    june_first_2020 = AppCount.june_first_2020()

    maintenance_orders =
      from(
        o in Order,
        join: c in assoc(o, :category),
        join: pc in assoc(c, :parent),
        where: o.status in ["unassigned", "assigned"] and o.property_id == ^property_id,
        where: o.inserted_at >= ^june_first_2020,
        where: pc.name != "Make Ready"
      )
      |> Repo.all(prefix: client_schema)

    maintenance_orders
  end

  def get_aggregate_by_ticket!(ticket) do
    from(
      o in @schema,
      where: o.ticket == ^ticket,
      preload: [category: [:parent], tenant: [], notes: [], assignments: [], property: []]
    )
    |> Repo.one!()
  end

  @doc """
  Our insight reports make use of work order by property. We also need
  categories and parent categories, as well as assignments. We already have the
  property, so don't need that. And we don't really care about notes or the
  tenant in this context, nor do we care about cancelled orders.

  This does include all "Make Ready" orders, so that's a thing to watch for.
  """
  def get_aggregate_by_property(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_id
      }) do
    from(
      o in @schema,
      where:
        o.property_id == ^property_id and o.status in ["completed", "assigned", "unassigned"],
      preload: [assignments: [], category: [:parent]]
    )
    |> Repo.all(prefix: client_schema)
  end
end
