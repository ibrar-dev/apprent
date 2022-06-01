defmodule AppCount.Accounts.PasswordResetRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Accounts.PasswordReset

  def create(account_id, admin_id) do
    %{account_id: account_id, admin_id: admin_id}
    |> insert()
  end
end
