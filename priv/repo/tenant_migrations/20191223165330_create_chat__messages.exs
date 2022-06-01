defmodule AppCount.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:chat__messages) do
      add :admin_id, references(:admins__admins, on_delete: :delete_all), null: false
      add :room_id, references(:chat__rooms, on_delete: :delete_all), null: false
      add :attachment_id, references(:data__uploads, on_delete: :nilify_all), null: true
      add :reply_id, references(:chat__messages, on_delete: :nilify_all), null: true
      add :text, :string, null: true

      timestamps()
    end
    create index(:chat__messages, [:attachment_id])
    create index(:chat__messages, [:room_id])
    create index(:chat__messages, [:admin_id])
    create index(:chat__messages, [:reply_id])
  end
end
