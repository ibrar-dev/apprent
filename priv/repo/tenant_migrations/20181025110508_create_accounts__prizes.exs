defmodule AppCount.Repo.Migrations.CreateAccountsPrizes do
  use Ecto.Migration

  def change do
    create table(:accounts__prizes) do
      add :name, :string, null: false
      add :icon, :string
      add :points, :integer, null: false
      add :price, :decimal
      add :url, :string, default: "", null: false
      add :promote, :boolean, default: true, null: false

      timestamps()
    end

  end
end
