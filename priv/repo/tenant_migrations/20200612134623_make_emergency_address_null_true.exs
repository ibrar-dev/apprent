defmodule AppCount.Repo.Migrations.MakeEmergencyAddressNullTrue do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__emergency_contacts) do
      modify(:address, :string, null: true)
    end
  end
end
