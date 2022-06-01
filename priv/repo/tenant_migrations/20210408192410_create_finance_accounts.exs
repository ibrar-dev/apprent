defmodule AppCount.Repo.Migrations.CreateFinanceAccounts do
  use Ecto.Migration

  def change do
    create table(:finance__accounts) do
      add :name, :string, null: false
      add :number, :string, null: false

      timestamps()
    end

  end
end
