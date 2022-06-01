defmodule AppCount.Repo.Migrations.AddAdminToPropertiesCharges do
  use Ecto.Migration

  def change do
    alter table(:properties__charges) do
      add :edits, :jsonb, default: "[]", null: false
    end
  end
end
