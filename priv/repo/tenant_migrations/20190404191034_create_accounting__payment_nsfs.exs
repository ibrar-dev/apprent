defmodule AppCount.Repo.Migrations.CreateAccountingPaymentNsfs do
  use Ecto.Migration

  def change do
    create table(:accounting__payment_nsfs) do
      add :payment_id, references(:accounting__payments, on_delete: :delete_all), null: false
      add :admin, :string, null: false
      add :proof, :string, null: true
      add :reason, :string, null: true
      add :date, :date, null: false

      timestamps()
    end
    create unique_index(:accounting__payment_nsfs, [:payment_id])
  end
end
