defmodule AppCount.Repo.Migrations.ChangeMarketRentToFeature do
  use Ecto.Migration

  def change do
    alter table(:units__market_rent) do
      remove :floor_plan_id
      add :feature_id, references(:properties__features, on_delete: :delete_all)
    end
  end
end
