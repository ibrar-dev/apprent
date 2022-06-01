defmodule AppCount.Repo.Migrations.AddPhoneToTenants do
  use Ecto.Migration

  def change do
    alter table(:properties__tenants) do
      add :phone, :string
    end
  end
end
