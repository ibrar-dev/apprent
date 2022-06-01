defmodule AppCount.Repo.Migrations.AddLeaseRefsToLeaseForms do
  use Ecto.Migration

  def change do
    rename table(:leases__forms), :lease_id, to: :form_id
    alter table(:leases__forms) do
      modify :application_id, :bigint, null: true
      add :lease_id, references(:leases__leases, on_delete: :delete_all)
      add :document_id, references(:data__uploads, on_delete: :delete_all)
    end

    create constraint(:leases__forms, :must_have_assoc, check: "application_id IS NOT NULL OR lease_id IS NOT NULL")
    create index(:leases__forms, [:lease_id])
    create index(:leases__forms, [:document_id])
  end
end
