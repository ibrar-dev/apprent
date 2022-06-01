defmodule AppCount.Repo.Migrations.CreateAccountingCashAccounts do
  use Ecto.Migration

  def change do
    create table(:accounting__cash_accounts) do
      add :name, :string

      timestamps()
    end

    create unique_index(:accounting__cash_accounts, [:name])
  end
end
