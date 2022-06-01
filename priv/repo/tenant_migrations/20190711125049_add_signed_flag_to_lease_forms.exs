defmodule AppCount.Repo.Migrations.AddSignedFlagToLeaseForms do
  use Ecto.Migration

  def change do
    alter table(:leases__forms) do
      add :signed, :boolean, default: false, null: false
    end
  end
end
