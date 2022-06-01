defmodule AppCount.Repo.Migrations.AddAttachmentToEvent do
  use Ecto.Migration

  def change do
    alter table(:properties__resident_events) do
      add :attachment, :string, null: true
    end
  end
end
