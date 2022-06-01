defmodule AppCount.Repo.Migrations.CreateAccountsPaymentSources do
  use Ecto.Migration

  def change do
    create table(:accounts__payment_sources) do
      add :lock, :naive_datetime
      add :type, :string, null: false
      add :name, :string, null: false
      add :num1, :text, null: false
      add :num2, :text, null: false
      add :exp, :string
      add :brand, :string, null: false
      add :active, :boolean, default: true, null: false
      add :account_id, references(:accounts__accounts, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:accounts__payment_sources, [:account_id])
  end
end
