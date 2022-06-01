defmodule AppCount.Repo.Migrations.CreateMaintenanceOffers do
  use Ecto.Migration

  def change do
    create table(:maintenance__offers) do
      add :tech_id, references(:maintenance__techs, on_delete: :delete_all), null: false
      add :order_id, references(:maintenance__orders, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:maintenance__offers, [:tech_id, :order_id])
  end
end
