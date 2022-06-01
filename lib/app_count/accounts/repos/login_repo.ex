defmodule AppCount.Accounts.LoginRepo do
  use AppCount.Core.GenericRepo, schema: AppCount.Accounts.Login

  def last_logins_by_account_id() do
    from(
      login in @schema,
      distinct: login.account_id,
      order_by: [desc: login.inserted_at]
    )
  end
end
