defmodule AppCount.Repo.Migrations.AddPassCodeToTechs do
  use Ecto.Migration

  def change do
    alter table(:maintenance__techs) do
      add :pass_code, :uuid
      add :identifier, :uuid, default: fragment("uuid_generate_v4()"), null: false
    end

    create unique_index(:maintenance__techs, [:identifier])
    create unique_index(:maintenance__techs, [:pass_code])
  end
end
