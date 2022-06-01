defmodule AppCount.Repo.Migrations.CreateProspectsProspects do
  use Ecto.Migration

  def change do
    create table(:prospects__prospects) do
      add :name, :string, null: false
      add :contact_date, :date
      add :traffic_source, :string
      add :address, :string
      add :move_in, :date
      add :next_follow_up, :date
      add :unit_type, :string
      add :phone, :string
      add :contact_type, :string
      add :contact_result, :string
      add :admin_id, references(:admins__admins, on_delete: :nilify_all)
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:prospects__prospects, [:admin_id])
    create index(:prospects__prospects, [:property_id])
  end
end
