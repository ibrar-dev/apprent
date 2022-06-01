defmodule AppCount.Repo.Migrations.CreateClients do
  use Ecto.Migration

  def up do
    create table(:clients) do
      add(:name, :string, null: false)
      add(:schema, :string, null: false)
      add(:features, :jsonb, null: false, default: "{}")
      add :status, :string, default: "active"

      timestamps()
    end

    create(unique_index(:clients, [:name]))
    create(unique_index(:clients, [:schema]))
  end
end
