defmodule AppCount.Repo.Migrations.CreateUnitsMarketRent do
  use Ecto.Migration

  def change do
    create table(:units__market_rent) do
      add :amount, :integer, null: false
      add :admin_id, references(:admins__admins, on_delete: :nilify_all)
      add :floor_plan_id, references(:properties__floor_plans, on_delete: :delete_all)

      timestamps()
    end

  end
end
