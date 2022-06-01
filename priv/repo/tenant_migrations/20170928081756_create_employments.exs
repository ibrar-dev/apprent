defmodule RentApply.Repo.Migrations.CreateEmployments do
  use Ecto.Migration

  def change do
    create table(:rent_apply__employments) do
      add :employer, :string, null: false
      add :address, :string, null: false
      add :duration, :string, null: false
      add :supervisor, :string, null: false
      add :salary, :decimal, null: false
      add :phone, :string, null: false
      add :application_id, references(:rent_apply__rent_applications, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:rent_apply__employments, [:application_id])
  end
end
