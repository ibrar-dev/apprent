defmodule RentApply.Repo.Migrations.CreatePersons do
  use Ecto.Migration

  def change do
    create table(:rent_apply__persons) do
      add :full_name, :string, null: false
      add :ssn, :string, null: false
      add :email, :string, null: false
      add :home_phone, :string
      add :work_phone, :string
      add :cell_phone, :string
      add :dob, :date, null: false
      add :dl_number, :string, null: false
      add :dl_state, :string, null: false
      add :application_id, references(:rent_apply__rent_applications, on_delete: :delete_all), null: false

      add :status, :string, null: false

      timestamps()
    end
    create index(:rent_apply__persons, [:application_id])
    check = "home_phone IS NOT NULL OR work_phone IS NOT NULL OR cell_phone IS NOT NULL"
    create constraint(:rent_apply__persons, :must_have_a_phone, check: check)
  end
end
