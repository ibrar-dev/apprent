defmodule Properties.Repo.Migrations.CreateProperties do
  use Ecto.Migration

  def change do
    create table(:properties__properties) do
      add :name, :string, null: false
      add :code, :string, null: false
      add :address, :json, default: "{}", null: false
      add :logo, :string

      timestamps()
    end
    create unique_index(:properties__properties, [:code])
  end
end
