defmodule AppCount.Repo.Migrations.CreateMessagingMailTemplates do
  use Ecto.Migration

  def change do
    create table(:messaging__mail_templates) do
      add :subject, :string, null: false
      add :body, :text, null: false
      add :creator, :text, null: false
      add :history, :jsonb, null: true

      timestamps()
    end
  end
end
