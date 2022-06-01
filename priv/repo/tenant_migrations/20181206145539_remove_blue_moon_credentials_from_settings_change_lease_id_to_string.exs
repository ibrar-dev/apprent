defmodule AppCount.Repo.Migrations.RemoveBlueMoonCredentialsFromSettingsChangeLeaseIdToString do
  use Ecto.Migration

  def change do
    alter table(:properties__settings) do
      remove :blue_moon_serial, :string
      remove :blue_moon_user, :string
      remove :blue_moon_password, :string
      remove :bluemoon_credentials_confirmed, :date
    end
  end
end
