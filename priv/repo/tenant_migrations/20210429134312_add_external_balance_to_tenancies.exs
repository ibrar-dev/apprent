defmodule AppCount.Repo.Migrations.AddExternalBalanceToTenancies do
  use Ecto.Migration

  def change do
    alter table(:tenants__tenancies) do
      add :external_balance, :decimal, scale: 2, precision: 10
    end
  end
end
