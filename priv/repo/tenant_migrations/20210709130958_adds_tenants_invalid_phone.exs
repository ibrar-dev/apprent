defmodule AppCount.Repo.Migrations.AddsTenantsInvalidPhone do
  use Ecto.Migration

  def change do
    alter table("tenants__tenants") do
      add :invalid_phone, :string, default: ""
    end
  end
end
