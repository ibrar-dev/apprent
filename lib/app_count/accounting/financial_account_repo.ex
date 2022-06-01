defmodule AppCount.Accounting.AccountRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Accounting.Account
end
