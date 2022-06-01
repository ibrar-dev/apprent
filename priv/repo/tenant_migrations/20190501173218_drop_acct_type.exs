defmodule AppCount.Repo.Migrations.DropAcctType do
  use Ecto.Migration

  def change do
    alter table(:accounting__accounts) do
      remove :acct_type
    end
  end
end
