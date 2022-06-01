defmodule AppCount.Repo.Migrations.CreateAccountsPurchases do
  use Ecto.Migration

  def change do
    create table(:accounts__purchases) do
      add :status, :string, null: false
      add :points, :integer, null: false
      add :prize_id, references(:accounts__prizes, on_delete: :delete_all), null: false
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:accounts__purchases, [:prize_id])
    create index(:accounts__purchases, [:tenant_id])
  end
end
