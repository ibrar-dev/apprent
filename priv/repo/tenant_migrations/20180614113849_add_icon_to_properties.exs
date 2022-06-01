defmodule AppCount.Repo.Migrations.AddIconToProperties do
  use Ecto.Migration

  def change do
    alter table(:properties__properties) do
      add :icon, :string
    end
  end
end
