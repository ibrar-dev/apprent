defmodule AppCount.Repo.Migrations.AddStatusToLeases do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__leases) do
      add :status, :jsonb, default: "{}", null: false
    end
  end
end
