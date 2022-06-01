defmodule AppCount.Repo.Migrations.CreateMessagingMailings do
  use Ecto.Migration

  def change do
    create table(:messaging__mailings) do
      add :send_at, :jsonb, null: true
      add :recipients, :jsonb, null: false
      add :subject, :string, null: false
      add :body, :text, null: false
      add :attachments, :jsonb, null: false
      add :property_ids, :jsonb, null: false
      add :sender, :text, null: false
      add :next_run, :integer

      timestamps()
    end

  end
end
