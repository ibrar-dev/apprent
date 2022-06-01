defmodule AppCount.ShortCodes do
  alias AppCount.ShortCodes.Tenants
  alias AppCount.ShortCodes.Applicants

  def parse_short_codes(body, params), do: Tenants.parse_short_codes(body, params)
  def parse_short_codes(body, params, :applicants), do: Applicants.parse_short_codes(body, params)
end
