defmodule AppCount.Repo.Migrations.AddScreeningFieldsToPersons do
  use Ecto.Migration

  def change do
    alter table(:properties__persons) do
      add :city, :string
      add :dob, :date
      add :income, :integer
      add :ssn, :string
      add :state, :string
      add :street, :string
      add :zip, :string
      add :screening_url, :string
      add :screening_order_id, :string
      add :screening_status, :string
      add :screening_decision, :string
      add :added_to_lease, :boolean, default: false, null: false
    end
  end
end
