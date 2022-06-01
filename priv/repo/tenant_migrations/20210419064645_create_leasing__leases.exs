defmodule AppCount.Repo.Migrations.CreateLeasingLeases do
  use Ecto.Migration

  def change do
    create table(:leasing__leases) do
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :date, :date, null: false
      add :admin, :string
      add :renewal_admin, :string
      add :no_renewal, :boolean, default: false, null: false
      add :customer_id, references(:accounting__customers, on_delete: :nothing), null: false
      add :document_id, references(:data__uploads, on_delete: :nothing), null: false
      add :unit_id, references(:properties__units, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:leasing__leases, [:customer_id])
    create index(:leasing__leases, [:document_id])
    create index(:leasing__leases, [:unit_id])
    create constraint(:leasing__leases, :valid_duration, check: "start_date < end_date")
  end
end
