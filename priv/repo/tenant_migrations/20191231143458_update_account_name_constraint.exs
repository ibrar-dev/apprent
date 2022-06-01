defmodule AppCount.Repo.Migrations.UpdateAccountNameConstraint do
  use Ecto.Migration

  def change do
    drop unique_index(:accounting__accounts, [:name])
    create unique_index(:accounting__accounts, [:name, :num])
  end
end
