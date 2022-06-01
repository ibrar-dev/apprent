defmodule AppCount.Repo.Migrations.CreateSettingsMoveOutReasons do
  use Ecto.Migration

  def change do
    create table(:settings__move_out_reasons) do
      add :name, :string, null: false

      timestamps()
    end

  end
end
