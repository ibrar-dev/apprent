defmodule AppCount.Repo.Migrations.AddTypeToDocuments do
  use Ecto.Migration

  def change do
    alter table(:properties__documents) do
      add :type, :string, null: false
    end
  end
end
