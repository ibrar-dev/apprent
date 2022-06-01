defmodule AppCount.Repo.Migrations.CreateRentApplyScreenings do
  use Ecto.Migration

  def change do
    create table(:rent_apply__screenings) do
      add :decision, :string, null: false, default: "pending"
      add :status, :string, null: false, default: "pending"
      add :order_id, :string, null: false
      add :url, :string
      add :person_id, references(:rent_apply__persons, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:rent_apply__screenings, [:person_id])
  end
end
