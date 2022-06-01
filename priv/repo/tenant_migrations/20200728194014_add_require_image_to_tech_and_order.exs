defmodule AppCount.Repo.Migrations.AddRequireImageToTechAndOrder do
  use Ecto.Migration

  def change do
    alter table(:maintenance__orders) do
      add :require_image, :boolean, default: false, null: false
    end

    alter table(:maintenance__techs) do
      add :require_image, :boolean, default: false, null: false
    end
  end
end
