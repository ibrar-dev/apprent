defmodule AppCount.Repo.Migrations.CreateChatReadReceipts do
  use Ecto.Migration

  def change do
    create table(:chat__read_receipts) do
      add :admin_id, references(:admins__admins, on_delete: :delete_all), null: false
      add :message_id, references(:chat__messages, on_delete: :delete_all), null: true
      add :room_id, references(:chat__rooms, on_delete: :delete_all), null: true

      timestamps()
    end
    create index(:chat__read_receipts, [:admin_id])
    create index(:chat__read_receipts, [:message_id])
    create index(:chat__read_receipts, [:room_id])
  end
end
