defmodule AppCount.Repo.Migrations.CreateCharges do
  use Ecto.Migration

  def change do
    create table(:accounting__charges) do
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all), null: false
      add :amount, :decimal, scale: 2, precision: 10, null: false
      add :status, :string, null: false, default: "pending"
      add :description, :text, null: false, default: ""
      add :charge_type_id, references(:accounting__charge_types, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:accounting__charges, [:charge_type_id])
  end
end
