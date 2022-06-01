defmodule AppCount.Repo.Migrations.AddIsBalanceToAccountCategory do
  use Ecto.Migration

  def change do
    alter table(:accounting__account_categories) do
      add :is_balance, :boolean, null: false, default: false
    end
  end
end
