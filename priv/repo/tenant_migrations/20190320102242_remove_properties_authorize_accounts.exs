defmodule AppCount.Repo.Migrations.RemovePropertiesAuthorizeAccounts do
  use Ecto.Migration

  def change do
    drop table(:properties__authorize_accounts)
  end
end
