defmodule AppCount.Repo.Migrations.CreateLeasesRenewalPeriods do
  use Ecto.Migration

  def change do
    create table(:leases__renewal_periods) do
      add :creator, :string, null: false
      add :approval_date, :date, null: true
      add :approval_admin, :string, null: true
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all)

      timestamps()
    end

  end
end
