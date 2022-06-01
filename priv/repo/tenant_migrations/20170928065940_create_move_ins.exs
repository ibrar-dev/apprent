defmodule RentApply.Repo.Migrations.CreateMoveIns do
  use Ecto.Migration

  def change do
    create table(:rent_apply__move_ins) do
      add :expected_move_in, :date, null: false
      add :application_id, references(:rent_apply__rent_applications, on_delete: :delete_all), null: false
      add :unit_number, :string, null: false

      timestamps()
    end

    create index(:rent_apply__move_ins, [:application_id])
  end
end
