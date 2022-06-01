defmodule AppCount.Repo.Migrations.FixFKeyRefOnPropertiesStocks do
  use Ecto.Migration

  def change do
    alter table(:properties__properties) do
      remove :stock_id
      add :stock_id, references(:maintenance__stocks, on_delete: :nilify_all)
    end
  end
end
