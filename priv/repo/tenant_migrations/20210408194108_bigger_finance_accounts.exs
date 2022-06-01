defmodule AppCount.Repo.Migrations.BiggerFinanceAccounts do
  use Ecto.Migration

  def change do
    alter table(:finance__accounts) do
      modify :number, :string, null: false, size: 8
      add :natural_balance, :string, null: false
      add :type, :string, null: false
      add :description, :string, null: false, default: ""
    end
  end
end
