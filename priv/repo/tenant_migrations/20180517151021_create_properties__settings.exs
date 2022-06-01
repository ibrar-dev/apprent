defmodule AppCount.Repo.Migrations.CreatePropertiesSettings do
  use Ecto.Migration

  def change do
    create table(:properties__settings) do
      add :application_fee, :decimal, null: false, default: 50
      add :admin_fee, :decimal, null: false, default: 150
      add :area_rate, :decimal, null: false, default: 1
      add :notice_period, :integer, null: false, default: 30
      add :grace_period, :integer, null: false, default: 7
      add :mtm_multiplier, :decimal, null: false, default: 1
      add :late_fee_threshold, :decimal, null: false, default: 50
      add :late_fee_amount, :decimal, null: false, default: 50
      add :late_fee_type, :string, null: false, default: "$"
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:properties__settings, [:property_id])

  end
end
