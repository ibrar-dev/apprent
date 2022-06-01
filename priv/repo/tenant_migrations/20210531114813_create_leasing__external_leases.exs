defmodule AppCount.Repo.Migrations.CreateLeasingExternalLeases do
  use Ecto.Migration

  def change do
    create table(:leasing__external_leases) do
      add :external_id, :string
      add :signature_id, :string
      add :parameters, :jsonb, null: false, default: "{}"
      add :provider, :string, null: false
      add :executed, :boolean, default: false, null: false
      add :archived, :boolean, default: false, null: false
      add :signators, :jsonb, default: "{}", null: false
      add :document_id, references(:data__uploads, on_delete: :nilify_all)
      add :unit_id, references(:properties__units, on_delete: :delete_all), null: false
      add :lease_id, references(:leasing__leases, on_delete: :nilify_all)
      add :admin_id, references(:admins__admins, on_delete: :nothing), null: false
      add :rent_application_id, references(:rent_apply__rent_applications, on_delete: :nilify_all)

      timestamps()
    end

    create index(:leasing__external_leases, [:rent_application_id])
    create index(:leasing__external_leases, [:unit_id])
    create index(:leasing__external_leases, [:document_id])
    create index(:leasing__external_leases, [:lease_id])
    create index(:leasing__external_leases, [:admin_id])
  end
end
