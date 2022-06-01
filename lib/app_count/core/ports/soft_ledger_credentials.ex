defmodule AppCount.Adapters.SoftLedger.Credential do
  @moduledoc false
  use AppCount.Core.ConfigLoader

  @keys [:client_secret, :client_id, :grant_type, :audience, :tenantUUID]

  @enforce_keys @keys
  defstruct @keys
end
