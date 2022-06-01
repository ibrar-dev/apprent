defmodule AppCount.Repo.Migrations.CreateDataUploads do
  use Ecto.Migration

  def change do
    create table(:data__uploads) do
      add :uuid, :uuid, null: false
      add :filename, :string, null: false
      add :size, :integer, null: false
      add :content_type, :string, null: false
      add :is_public, :boolean, null: false, default: false
      add :is_loading, :boolean, null: false, default: true

      timestamps()
    end

    create unique_index(:data__uploads, [:uuid])
  end
end
