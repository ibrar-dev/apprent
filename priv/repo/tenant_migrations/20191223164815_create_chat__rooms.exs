defmodule AppCount.Repo.Migrations.CreateChatRooms do
  use Ecto.Migration

  def change do
    create table(:chat__rooms) do
      add :description, :string, null: true
      add :name, :string, null: true
      add :type, :string, null: false, default: "Custom"
      add :image_id, references(:data__uploads, on_delete: :nilify_all), null: true

      timestamps()
    end

    create index(:chat__rooms, [:image_id])
  end
end
