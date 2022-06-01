defmodule AppCount.Repo.Migrations.CreateMaintenanceCardItems do
  use Ecto.Migration

  def change do
    create table(:maintenance__card_items) do
      add :name, :string, null: false
      add :notes, :text
      add :scheduled, :date
      add :completed, :date
      add :card_id, references(:maintenance__cards, on_delete: :delete_all), null: false
      add :tech_id, references(:maintenance__techs, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:maintenance__card_items, [:card_id, :name])
    create index(:maintenance__card_items, [:tech_id])
  end
end
