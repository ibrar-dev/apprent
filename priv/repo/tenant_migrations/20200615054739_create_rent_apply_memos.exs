defmodule AppCount.Repo.Migrations.CreateRentApplyMemos do
  use Ecto.Migration

  def change do
    create table(:rent_apply__memos) do
      add :note, :string, null: false
      add :application_id, references(:rent_apply__rent_applications, on_delete: :delete_all), null: false
      add :admin_id, references(:admins__admins, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:rent_apply__memos, [:application_id])
  end
end
