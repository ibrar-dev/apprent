defmodule AppCount.Repo.Migrations.CreateLeasingCharges do
  use Ecto.Migration

  def change do
    create table(:leasing__charges) do
      add :amount, :decimal, null: false
      add :schedule, :map
      add :from_date, :date
      add :to_date, :date
      add :next_bill_date, :date
      add :edits, :jsonb, default: "[]", null: false
      add :lease_id, references(:leasing__leases, on_delete: :nothing)
      add :charge_code_id, references(:leasing__charge_codes, on_delete: :nothing)

      timestamps()
    end

    create index(:leasing__charges, [:lease_id])
    create index(:leasing__charges, [:charge_code_id])
  end
end
