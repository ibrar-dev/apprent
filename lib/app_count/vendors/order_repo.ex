defmodule AppCount.Vendors.OrderRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Vendors.Order,
    preloads: [:category]

  # belongs_to :property, AppCount.Properties.Property
  # belongs_to :vendor, AppCount.Vendors.Vendor
  # belongs_to :card_item, AppCount.Maintenance.CardItem
  # belongs_to :unit, AppCount.Properties.Unit
  # belongs_to :tenant, AppCount.Tenants.Tenant
  # belongs_to :admin, AppCount.Admins.Admin
  # has_many :notes, AppCount.Vendors.Note

  def currently_open(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_id
      })
      when is_list(property_id) do
    from(
      o in AppCount.Vendors.Order,
      join: u in assoc(o, :unit),
      join: p in assoc(u, :property),
      where: p.id in ^property_id and o.status != "Completed"
    )
    |> Repo.all(prefix: client_schema)
  end

  def currently_open(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_id
      }) do
    from(
      o in AppCount.Vendors.Order,
      join: u in assoc(o, :unit),
      join: p in assoc(u, :property),
      where: p.id == ^property_id and o.status != "Completed"
    )
    |> Repo.all(prefix: client_schema)
  end
end
