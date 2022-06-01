defmodule AppCount.Repo.Migrations.CreateAssignments do
  use Ecto.Migration

  def change do
    create table(:maintenance__assignments) do
      add :status, :string, null: false
      add :rating, :integer
      add :completed_at, :naive_datetime
      add :confirmed_at, :naive_datetime
      add :tech_id, references(:maintenance__techs, on_delete: :delete_all), null: false
      add :order_id, references(:maintenance__orders, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:maintenance__assignments, [:tech_id])
    create index(:maintenance__assignments, [:order_id])
  end
end
