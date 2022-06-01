defmodule AppCount.Repo.Migrations.AddDatesToCharges do
  use Ecto.Migration

  def change do
    alter table(:properties__charges) do
      add :from_date, :date
      add :to_date, :date
    end
  end
end
