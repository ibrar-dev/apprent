defmodule AppCount.Repo.Migrations.CreateSettingsDamages do
  use Ecto.Migration

  def change do
    create table(:settings__damages) do
      add :name, :string, null: false

      timestamps()
    end

  end
end
