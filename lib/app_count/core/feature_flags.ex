defmodule AppCount.Core.FeatureFlags do
  @moduledoc """

  values:
  -------
  true / false are set in config/test.exs, config/dev.ex, and config/prod.ex
  config :app_count, AppCount.Core.FeatureFlags, using_soft_ledger: true


  retrieve values like this:
  -------------------------
  AppCount.Core.FeatureFlags.load().using_soft_ledger

  """

  use AppCount.Core.ConfigLoader

  @keys [:using_soft_ledger]

  @enforce_keys @keys
  defstruct @keys
end
