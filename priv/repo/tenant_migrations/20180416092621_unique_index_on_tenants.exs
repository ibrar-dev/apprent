defmodule AppCount.Repo.Migrations.UniqueIndexOnTenants do
  use Ecto.Migration

  def change do
    alter table(:properties__tenants) do
      modify :email, :string, null: false, default: "unknown@example.com"
    end
    create unique_index(:properties__tenants, [:first_name, :last_name, :email])
  end
end
