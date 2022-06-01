defmodule AppCount.Repo.Migrations.AddCreationDateToVendorOrder do
  use Ecto.Migration

  def change do
    alter table(:vendors__orders) do
      add :creation_date, :date
    end
  end
end
