defmodule AppCount.Repo.Migrations.AddProjectToPurchaseOrders do
  use Ecto.Migration

  def change do
    alter table(:purchases__purchase_orders) do
      add :project_id, references(:purchases__purchase_order_projects)
    end
  end
end
