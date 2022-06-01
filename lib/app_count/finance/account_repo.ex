defmodule AppCount.Finance.AccountRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Finance.Account,
    topic: AppCount.Core.FinanceAccountTopic
end
