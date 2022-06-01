defmodule AppCount.Repo.Migrations.RentApplyEmergencyContactsAddEmailColumn do
  use Ecto.Migration

  def change do
    alter table("rent_apply__emergency_contacts") do
      add :email, :citext, null: true
    end
  end
end
