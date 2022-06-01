defmodule AppCount.Repo.Migrations.CreateLeasesClosings do
  use Ecto.Migration

  def change do
    create table(:leases__closings) do
      add :date, :date, null: false
      add :balance, :decimal, null: false
      add :admin, :string, null: false
      add :check_id, references(:accounting__checks, on_delete: :nilify_all)
      add :lease_id, references(:leases__leases, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:leases__closings, [:check_id])
    create unique_index(:leases__closings, [:lease_id])
  end
end
