defmodule AppCount.Repo.Migrations.ChangeCheckRefs do
  use Ecto.Migration

  def change do
    alter table(:accounting__checks) do
      remove :property_id
      remove :invoice_id
      remove :payee_id
      add :invoicing_id, references(:accounting__invoices, on_delete: :delete_all), null: false
    end

    create index(:accounting__checks, [:invoicing_id])
  end
end
