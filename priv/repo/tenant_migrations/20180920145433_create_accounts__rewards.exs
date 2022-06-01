defmodule AppCount.Repo.Migrations.CreateAccountsRewards do
  use Ecto.Migration

  def change do
    create table(:accounts__rewards) do
      add :amount, :integer, null: false
      add :reason, :string, null: false
      add :created_by, :string, null: false
      add :reversal, :jsonb, null: true
      add :account_id, references(:properties__tenants, on_delete: :delete_all), null: false

      timestamps()
    end

    alter table(:properties__settings) do
      add :rewards, :boolean, default: true
    end
  end
end
