defmodule AppCount.Repo.Migrations.CreateAccountingPostMonths do
  use Ecto.Migration

  def change do
    create table(:accounting__post_months) do
      add :month, :date, null: false
      add :closed_on, :date, null: false
      add :admin_id, references(:admins__admins, on_delete: :nilify_all)
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:accounting__post_months, [:admin_id])
    create unique_index(:accounting__post_months, [:property_id, :month])
  end
end
