defmodule AppCount.Repo.Migrations.AddBlueMoonCredentialsToPropertySettings do
  use Ecto.Migration

  def change do
    alter table(:properties__settings) do
      add :blue_moon_serial, :string, null: true
      add :blue_moon_user, :string, null: true
      add :blue_moon_password, :string, null: true
    end
  end
end
