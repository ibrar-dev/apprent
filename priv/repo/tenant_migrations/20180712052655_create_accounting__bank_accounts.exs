defmodule AppCount.Repo.Migrations.CreateAccountingBankAccounts do
  use Ecto.Migration

  def change do
    create table(:accounting__bank_accounts) do
      add :name, :string, null: false
      add :account_number, :string, null: false
      add :routing_number, :string, null: false

      timestamps()
    end

  end
end
