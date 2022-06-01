defmodule AppCount.Adapters.SoftLedger.Config do
  @moduledoc """

  AppCount.Adapters.SoftLedger.Config.load().parent_id

  """
  use AppCount.Core.ConfigLoader

  @keys [:url, :parent_id, :ar_account_id]

  @enforce_keys @keys
  defstruct @keys
end
