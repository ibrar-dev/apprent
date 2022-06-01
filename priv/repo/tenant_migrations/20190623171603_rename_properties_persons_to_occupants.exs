defmodule AppCount.Repo.Migrations.RenamePropertiesPersonsToOccupants do
  use Ecto.Migration

  def change do
    alter table(:properties__persons) do
      remove :status
      remove :city
      remove :dob
      remove :ssn
      remove :state
      remove :street
      remove :zip
      remove :income
      remove :screening_url
      remove :screening_order_id
      remove :screening_status
      remove :screening_decision
      remove :added_to_lease
      remove :gateway_xml
    end

    create table(:leases__screenings) do
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all)
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :phone, :string, null: false
      add :email, :citext, null: false
      add :city, :string, null: false
      add :income, :decimal, null: false
      add :dob, :date, null: false
      add :ssn, :text, null: false
      add :state, :string, null: false
      add :street, :string, null: false
      add :zip, :string, null: false
      add :url, :string
      add :order_id, :string
      add :status, :string, null: false, default: "pending"
      add :decision, :string, null: false, default: "pending"
      add :gateway_xml, :text

      timestamps()
    end

    execute "alter table #{prefix()}.properties__persons rename constraint properties__persons_pkey to properties__occupants_pkey"
    execute "alter table #{prefix()}.properties__persons rename constraint properties__persons_lease_id_fkey to properties__occupants_lease_id_fkey"
    execute "ALTER SEQUENCE #{prefix()}.properties__persons_id_seq RENAME TO properties__occupants_id_seq;"
    rename table(:properties__persons), to: table(:properties__occupants)
  end
end
