defmodule AppCount.Properties.Server.MiniPropertyRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Properties.Server.MiniProperty,
    preloads: [:setting, units: [leases: [occupancies: [:tenant]]]]
end
