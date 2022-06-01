defmodule AppCount.Repo.Migrations.AddClassRefToInvoices do
  use Ecto.Migration

  def change do
    alter table(:accounting__invoices) do
      add :class_id, references(:accounting__classes, on_delete: :delete_all), null: false
    end

    create index(:accounting__invoices, [:class_id])
  end
end
