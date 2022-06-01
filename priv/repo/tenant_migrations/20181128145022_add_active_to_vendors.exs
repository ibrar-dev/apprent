defmodule AppCount.Repo.Migrations.AddActiveToVendors do
  use Ecto.Migration

  def change do
    alter table(:vendors__vendors) do
      add :active, :boolean, default: true, null: false
    end
  end
end
