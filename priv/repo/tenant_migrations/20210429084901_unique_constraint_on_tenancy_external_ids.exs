defmodule AppCount.Repo.Migrations.UniqueConstraintOnTenancyExternalIds do
  use Ecto.Migration

  def change do
    create unique_index(:tenants__tenancies, [:external_id])
  end
end
