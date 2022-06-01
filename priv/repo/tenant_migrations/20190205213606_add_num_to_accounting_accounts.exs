defmodule AppCount.Repo.Migrations.AddNumToAccountingAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounting__accounts) do
      add :num, :integer, null: true
    end
  end
end
