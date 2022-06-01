defmodule RentApply.Repo.Migrations.CreateSavedForms do
  use Ecto.Migration

  def change do
    create table(:rent_apply__saved_forms) do
      add :email, :string, null: false
      add :pin, :string, null: false
      add :crypted_form, :text, null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:rent_apply__saved_forms, [:email, :property_id])
  end
end
