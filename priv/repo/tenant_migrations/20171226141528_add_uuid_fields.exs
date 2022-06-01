defmodule AppCount.Repo.Migrations.AddUUIDFields do
  use Ecto.Migration

  def change do
    alter table(:properties__tenants) do
      add :uuid, :uuid
    end

    alter table(:properties__units) do
      add :uuid, :uuid
    end

    alter table(:maintenance__orders) do
      add :uuid, :uuid
    end
  end
end
