defmodule AppCount.Repo.Migrations.AddShownRefToDocuments do
  use Ecto.Migration

  def change do
    alter table(:properties__documents) do
      add :visible, :boolean, default: true, null: false
    end
  end
end
