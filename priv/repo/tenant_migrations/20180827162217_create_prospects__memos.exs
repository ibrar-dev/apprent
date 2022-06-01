defmodule AppCount.Repo.Migrations.CreateProspectsMemo do
  use Ecto.Migration

  def change do
    create table(:prospects__memos) do
      add :admin, :string
      add :notes, :string
      add :prospect_id, references(:prospects__prospects, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:prospects__memos, [:prospect_id])
  end
end
