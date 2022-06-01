defmodule AppCount.Repo.Migrations.CreateTenantsTenancies do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS btree_gist"
    create table(:tenants__tenancies) do
      add :actual_move_in, :date
      add :actual_move_out, :date
      add :expected_move_in, :date
      add :expected_move_out, :date
      add :start_date, :date, null: false
      add :external_id, :string
      add :notice_date, :date
      add :eviction_file_date, :date
      add :eviction_court_date, :date
      add :eviction_notes, :text
      add :move_out_reason_id, references(:settings__move_out_reasons, on_delete: :delete_all)
      add :tenant_id, references(:tenants__tenants, on_delete: :delete_all), null: false
      add :customer_id, references(:accounting__customers, on_delete: :nothing), null: false
      add :unit_id, references(:properties__units, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:tenants__tenancies, [:tenant_id])
    create index(:tenants__tenancies, [:customer_id])
    create index(:tenants__tenancies, [:unit_id])

    create constraint(:tenants__tenancies, :non_future_move_out, check: "actual_move_out <= now()")
    create constraint(:tenants__tenancies, :non_future_move_in, check: "actual_move_in <= now()")
  end
end
