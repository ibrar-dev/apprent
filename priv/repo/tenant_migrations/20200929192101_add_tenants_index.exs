defmodule AppCount.Repo.Migrations.AddTenantsIndex do
  use Ecto.Migration

  def change do
    create index("tenants__tenants", [:email])
  end
end
