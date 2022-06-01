defmodule AppCount.Repo.Migrations.CreateMaterialsToolboxItems do
  use Ecto.Migration

  def change do
    create table(:materials__toolbox_items) do
      add :admin, :string, null: true
      add :status, :string, null: false, default: "pending"
      add :history, :jsonb, null: true
      add :stock_id, references(:materials__stocks, on_delete: :delete_all), null: false
      add :material_id, references(:materials__materials, on_delete: :delete_all), null: false
      add :tech_id, references(:maintenance__techs, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:materials__toolbox_items, [:stock_id])
    create index(:materials__toolbox_items, [:material_id])
    create index(:materials__toolbox_items, [:tech_id])
  end
end
