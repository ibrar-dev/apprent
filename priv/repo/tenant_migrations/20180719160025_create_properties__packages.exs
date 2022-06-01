defmodule AppCount.Repo.Migrations.CreatePropertiesPackages do
  use Ecto.Migration

  def change do
    create table(:properties__packages) do
      add :status, :string, default: "Pending", null: false
      add :condition, :string, null: true
      add :last_emailed, :date, null: true
      add :type, :string, null: true
      add :tracking_number, :string, null: true
      add :carrier, :string, default: "Other", null: false
      add :name, :string , null: true
      add :unit_id, references(:properties__units, on_delete: :delete_all), null: false

      timestamps()
    end

  end
end
