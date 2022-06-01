defmodule AppCount.Repo.Migrations.AddNoAccessToWorkOrders do
  use Ecto.Migration

  def change do
    alter table(:maintenance__orders) do
      add :no_access, :jsonb
    end
  end
end
