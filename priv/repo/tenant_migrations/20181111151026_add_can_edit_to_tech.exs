defmodule AppCount.Repo.Migrations.AddCanEditToTech do
  use Ecto.Migration

  def change do
    alter table(:maintenance__techs) do
      add :can_edit, :boolean, default: false, null: false
    end
  end
end
