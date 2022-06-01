defmodule AppCount.Repo.Migrations.AddRegionToProperty do
  use Ecto.Migration

  def change do
    alter table(:properties__properties) do
      add :region, :string, default: "", null: false
    end
  end
end
