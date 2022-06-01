defmodule AppCount.Repo.Migrations.AddCancellationToWorkOrders do
  use Ecto.Migration

  def change do
    alter table(:maintenance__orders) do
      add :cancellation, :jsonb
    end
  end
end
