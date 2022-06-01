defmodule RentApply.Repo.Migrations.CreateRentApplications do
  use Ecto.Migration

  def change do
    create table(:rent_apply__rent_applications) do
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "submitted"
      timestamps()
    end

  end
end
