defmodule AppCount.Repo.Migrations.CreateRentApplyLeases do
  use Ecto.Migration

  def change do
    create table(:rent_apply__leases) do
      add :persons, {:array, :json}, default: "{}"
      add :lease_date, :date
      add :unit_keys, :integer
      add :mail_keys, :integer
      add :other_keys, :integer
      add :deposit_type, :string
      add :deposit_value, :string
      add :bug_inspected, :boolean, default: false, null: false
      add :bug_awareness_level, :integer
      add :buy_out_fee, :decimal
      add :concession_fee, :decimal
      add :fitness_card_number, :string
      add :gate_access_remote, :boolean, default: false, null: false
      add :gate_access_code, :boolean, default: false, null: false
      add :gate_access_card, :boolean, default: false, null: false
      add :lost_card_fee, :boolean, default: false, null: false
      add :lost_remote_fee, :boolean, default: false, null: false
      add :code_change_fee, :boolean, default: false, null: false
      add :insurance_company, :string
      add :monthly_discount, :decimal
      add :one_time_concession, :decimal
      add :concession_months, {:array, :date}, default: "{}"
      add :other_discount, :text
      add :washer_rent, :decimal
      add :washer_type, :string
      add :washer_serial, :string
      add :dryer_serial, :string
      add :smart_fee, :decimal
      add :waste_cost, :decimal
      add :application_id, references(:rent_apply__rent_applications, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:rent_apply__leases, [:application_id])
  end
end
