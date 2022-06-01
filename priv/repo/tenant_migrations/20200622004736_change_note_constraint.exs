defmodule AppCount.Repo.Migrations.ChangeNoteConstraint do
  use Ecto.Migration

  def change do
    drop constraint(:maintenance__notes, :must_have_body)
    create constraint(:maintenance__notes, :must_have_body, check: "text IS NOT NULL OR image IS NOT NULL OR attachment_id IS NOT NULL")
  end
end
