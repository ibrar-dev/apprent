defmodule AppCount.Repo.Migrations.PolymorphicReceipts do
  use Ecto.Migration

  def change do
    alter table(:accounting__receipts) do
      add :concession_id, references(:accounting__charges, on_delete: :delete_all)
      modify :payment_id, :bigint, null: true
    end

    create constraint(:accounting__receipts, :must_have_credit, check: "concession_id IS NOT NULL OR payment_id IS NOT NULL")
    create index(:accounting__receipts, [:concession_id])
  end
end
