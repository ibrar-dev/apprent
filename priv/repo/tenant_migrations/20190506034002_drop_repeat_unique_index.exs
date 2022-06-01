defmodule AppCount.Repo.Migrations.DropRepeatUniqueIndex do
  use Ecto.Migration

  def change do
    drop_if_exists unique_index(:accounting__closings, [:property_id, :month])
  end
end
