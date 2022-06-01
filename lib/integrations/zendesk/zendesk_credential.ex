defmodule AppCount.Adapters.Zendesk.Credential do
  use AppCount.Core.ConfigLoader

  @keys [:subdomain, :user, :api_token]

  @enforce_keys @keys
  defstruct @keys
end
