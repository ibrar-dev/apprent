defmodule AppCount.Repo.Migrations.AdjustAccountsAgain do
  use Ecto.Migration

  def change do
    alter table(:accounting__accounts) do
      add :acct_type, :string, null: false, default: "Regular"
      add :total_account, :integer, null: true
    end

    create unique_index(:accounting__accounts, [:num])
  end
end
