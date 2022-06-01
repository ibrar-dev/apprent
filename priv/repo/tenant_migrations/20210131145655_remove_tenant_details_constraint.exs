defmodule AppCount.Repo.Migrations.RemoveTenantDetailsConstraint do
  use Ecto.Migration

  def change do
    drop unique_index(:tenants__tenants, [:first_name, :last_name, :email])
  end
end
