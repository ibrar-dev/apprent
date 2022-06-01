defmodule AppCount.Adapters.Twilio.Credential do
  use AppCount.Core.ConfigLoader

  @keys [:sid, :token, :phone_from, :url]

  @enforce_keys @keys
  defstruct @keys
end
