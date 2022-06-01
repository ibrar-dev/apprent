defmodule AppCount.Repo.Migrations.EmailNotRequiredForTenants do
  use Ecto.Migration

  def up do
    alter table(:properties__tenants) do
      modify :email, :string, null: true
    end
    execute "alter table #{prefix()}.properties__tenants alter email drop default"
  end

  def down do
    alter table(:properties__tenants) do
      modify :email, :string, null: false, default: "unknown@example.com"
    end
  end
end
