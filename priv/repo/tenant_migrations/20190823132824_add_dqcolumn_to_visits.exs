defmodule AppCount.Repo.Migrations.AddDqcolumnToVisits do
  use Ecto.Migration

  def change do
    alter table(:properties__visits) do
      add :delinquency, :naive_datetime
    end
  end
end
