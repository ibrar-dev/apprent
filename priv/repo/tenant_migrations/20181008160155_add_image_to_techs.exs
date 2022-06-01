defmodule AppCount.Repo.Migrations.AddImageToTechs do
  use Ecto.Migration

  def change do
    alter table(:maintenance__techs) do
      add :image, :string
    end
  end
end
