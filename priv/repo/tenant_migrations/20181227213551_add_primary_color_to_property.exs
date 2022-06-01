defmodule AppCount.Repo.Migrations.AddPrimaryColorToProperty do
  use Ecto.Migration

  def change do
    alter table(:properties__properties) do
      add :primary_color, :string, null: false, default: "#6ECD0B"
    end
  end
end
