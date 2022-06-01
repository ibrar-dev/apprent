defmodule AppCount.Repo.Migrations.ChangeShowingsUniqueConstraints do
  use Ecto.Migration

  def up do
    drop index(:prospects__showings, [:prospect_id, :date])
    exclude = ~s|gist (date WITH =, prospect_id WITH =, int4range("start_time", "end_time") WITH &&)|
    create constraint(:prospects__showings, :scheduling_conflict, exclude: exclude)
  end

  def down do
    drop constraint(:prospects__showings, :scheduling_conflict)
    create unique_index(:prospects__showings, [:prospect_id, :date])
  end
end
