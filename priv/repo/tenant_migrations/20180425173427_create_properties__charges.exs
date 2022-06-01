defmodule AppCount.Repo.Migrations.CreatePropertiesCharges do
  use Ecto.Migration

  def change do
    create table(:properties__charges) do
      add :amount, :decimal, null: false
      add :description, :text
      add :schedule, :map, null: false, default: "{}"
      add :next_bill, :integer
      add :occupancy_id, references(:properties__occupancies, on_delete: :delete_all), null: false
      add :charge_type_id, references(:accounting__charge_types, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:properties__charges, [:occupancy_id])
    create index(:properties__charges, [:charge_type_id])

    create unique_index(:accounting__charge_types, [:code])
    create unique_index(:accounting__charge_types, [:description])
  end
end
