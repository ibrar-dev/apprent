defmodule AppCount.Repo.Migrations.DropUnitTypes do
  use Ecto.Migration

  def change do
    alter table(:properties__units) do
      remove :unit_type_id
    end

    drop table(:properties__unit_types)
  end
end
