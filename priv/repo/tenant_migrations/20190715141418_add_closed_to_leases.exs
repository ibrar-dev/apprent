defmodule AppCount.Repo.Migrations.AddClosedToLeases do
  use Ecto.Migration

  def change do
    alter table(:leases__leases) do
      add :closed, :boolean, default: false, null: false
    end
  end
end
