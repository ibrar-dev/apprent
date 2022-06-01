defmodule AppCount.Repo.Migrations.AddNotesIndex do
  use Ecto.Migration

  def change do
    create index("maintenance__notes", [:attachment_id])
  end
end
