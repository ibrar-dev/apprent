defmodule AppCount.Repo.Migrations.AddLockedFlagToLeases do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__leases) do
      add :locked, :boolean, null: false, default: false
    end
  end
end
