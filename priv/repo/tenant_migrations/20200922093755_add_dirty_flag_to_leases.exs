defmodule AppCount.Repo.Migrations.AddDirtyFlagToLeases do
  use Ecto.Migration

  def change do
    alter table(:leases__leases) do
      add :dirty, :boolean, default: false, null: false
    end
  end
end
