defmodule AppCount.Repo.Migrations.CreatePropertiesInsurances do
  use Ecto.Migration

  def change do
    create table(:properties__insurances) do
      add :title, :string
      add :canceled, :date
      add :reinstate, :date
      add :number, :string, null: false
      add :amount, :decimal, null: false
      add :company, :string, null: false
      add :begins, :date, null: false
      add :ends, :date, null: false
      add :renewal, :boolean, default: false, null: false
      add :legal_liability, :boolean, default: false, null: false
      add :satisfies_move_in, :boolean, default: false, null: false
      add :interested_party, :boolean, default: false, null: false
      add :pet_endorsement, :boolean, default: false, null: false
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:properties__insurances, [:tenant_id])
  end
end
