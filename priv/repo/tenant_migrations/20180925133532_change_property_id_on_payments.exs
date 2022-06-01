defmodule AppCount.Repo.Migrations.ChangePropertyIdOnPayments do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      remove :property_id
      add :payment_source_id, references(:accounts__payment_sources, on_delete: :nilify_all)
    end
    create index(:accounting__payments, [:payment_source_id])
  end
end
