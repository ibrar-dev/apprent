defmodule AppCount.Repo.Migrations.AddActiveToTechs do
  use Ecto.Migration

  def change do
    alter table(:maintenance__techs) do
      add :active, :boolean, default: true, null: false
    end
  end
end
