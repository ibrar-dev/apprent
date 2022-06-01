defmodule AppCount.Repo.Migrations.CreateStocks do
  use Ecto.Migration

  def change do
    create table(:maintenance__stocks) do
      add :name, :string, null: false

      timestamps()
    end

    create unique_index(:maintenance__stocks, [:name])

  end
end
