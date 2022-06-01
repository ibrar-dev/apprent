defmodule AppCount.Repo.Migrations.RemoveStatusFromWorkOrders do
  use Ecto.Migration

  def change do
    alter table(:maintenance__orders) do
      remove :status
    end
  end
end
