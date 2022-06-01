defmodule AppCount.Repo.Migrations.AddTypeToTechs do
  use Ecto.Migration

  def change do
    alter table(:maintenance__techs) do
      add :type, :string, null: false, default: "Tech"
      add :description, :text, null: false, default: ""
    end
  end
end
