defmodule AppCount.Repo.Migrations.CreateSettingsCredentialSets do
  use Ecto.Migration

  def change do
    create table(:settings__credential_sets) do
      add :credentials, :map, null: false, default: "{}"
      add :provider, :string, null: false

      timestamps()
    end

  end
end
