defmodule AppCount.Repo.Migrations.CreateAccountsAutopays do
  use Ecto.Migration

  def change do
    create table(:accounts__autopays) do
      add :day, :integer, null: false
      add :active, :boolean, default: true, null: false
      add :max_amount, :integer, null: false
      add :account_id, references(:accounts__accounts, on_delete: :delete_all), null: false
      add :payment_source_id, references(:accounts__payment_sources, on_delete: :delete_all), null: false
      add :last_run, :date, null: true

      timestamps()
    end

    create unique_index(:accounts__autopays, [:account_id])
    create unique_index(:accounts__autopays, [:payment_source_id])
  end
end
