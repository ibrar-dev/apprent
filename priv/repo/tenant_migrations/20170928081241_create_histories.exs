defmodule RentApply.Repo.Migrations.CreateHistories do
  use Ecto.Migration

  def change do
    create table(:rent_apply__histories) do
      add :address, :string, null: false
      add :landlord_name, :string
      add :landlord_phone, :string
      add :rent, :boolean, default: false, null: false
      add :rental_amount, :decimal
      add :residency_length, :string, null: false
      add :application_id, references(:rent_apply__rent_applications, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:rent_apply__histories, [:application_id])
  end
end
