defmodule AppCount.Maintenance.CardItemRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Maintenance.CardItem,
    preloads: [card: :unit]

  # add these preloads in the future as needed:
  # belongs_to :tech, AppCount.Maintenance.Tech
  # belongs_to :vendor, AppCount.Vendors.Vendor

  alias AppCount.Repo
  import Ecto.Query
end
