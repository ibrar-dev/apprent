defmodule AppCount.Repo.Migrations.CreateMaterialsWarehouses do
  use Ecto.Migration

  def change do
    create table(:materials__warehouses) do
      add :name, :string
      add :image, :string

      timestamps()
    end

  end
end
