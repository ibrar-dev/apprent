defmodule RentApply.Repo.Migrations.CreateIncomes do
  use Ecto.Migration

  def change do
    create table(:rent_apply__incomes) do
      add :description, :string, null: false
      add :salary, :decimal, null: false
      add :application_id, references(:rent_apply__rent_applications, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:rent_apply__incomes, [:application_id])
  end
end
