defmodule AppCount.Repo.Migrations.AddTypeToLeases do
  use Ecto.Migration

  def change do
    alter table(:properties__leases) do
      add :type, :string, default: "lease", null: false
    end
  end
end
