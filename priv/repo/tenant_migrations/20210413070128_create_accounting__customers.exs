defmodule AppCount.Repo.Migrations.CreateAccountingCustomers do
  use Ecto.Migration

  def change do
    create table(:accounting__customers) do
      add :name, :string, null: false
      add :type, :string, null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :external_id, :string

      timestamps()
    end

  end
end
