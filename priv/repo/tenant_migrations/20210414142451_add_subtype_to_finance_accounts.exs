defmodule AppCount.Repo.Migrations.AddSubtypeToFinanceAccounts do
  use Ecto.Migration

  def change do
    alter table(:finance__accounts) do
      add :subtype, :string, null: false
    end
  end
end
