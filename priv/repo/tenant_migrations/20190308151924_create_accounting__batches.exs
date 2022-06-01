defmodule AppCount.Repo.Migrations.CreateAccountingBatchs do
  use Ecto.Migration

  def change do
    create table(:accounting__batches) do
      add :property_id, references(:properties__properties, on_delete: :nothing), null: false
      add :closed, :boolean, null: false, default: false
      add :closed_by, :string, null: true
      add :date, :date, null: false

      timestamps()
    end

  end
end
