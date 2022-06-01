defmodule AppCount.Repo.Migrations.CreateChatRoomMembers do
  use Ecto.Migration

  def change do
    create table(:chat__room_members) do
      add :admin_id, references(:admins__admins, on_delete: :delete_all), null: false
      add :room_id, references(:chat__rooms, on_delete: :delete_all), null: false
      add :is_admin, :boolean, null: false, default: false
      add :visible, :boolean, null: false, default: true

      timestamps()
    end

    create index(:chat__room_members, [:room_id])
    create index(:chat__room_members, [:admin_id])
  end
end
