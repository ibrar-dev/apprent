defmodule AppCount.Repo.Migrations.MakeUnitNumberNullable do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__move_ins) do
      modify :unit_number, :string, null: true
    end
  end
end
