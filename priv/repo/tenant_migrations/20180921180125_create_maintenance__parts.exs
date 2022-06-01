defmodule AppCount.Repo.Migrations.CreateMaintenanceParts do
  use Ecto.Migration

  def change do
    create table(:maintenance__parts) do
      add :name, :string
      add :status, :string
      add :order_id, references(:maintenance__orders, on_delete: :delete_all), null: false

      timestamps()
    end

    alter table(:vendors__orders) do
      add :scheduled, :date, null: true
    end
  end
end
