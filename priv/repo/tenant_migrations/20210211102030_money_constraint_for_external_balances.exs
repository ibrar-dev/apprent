defmodule AppCount.Repo.Migrations.MoneyConstraintForExternalBalances do
  use Ecto.Migration

  def change do
    alter table(:leases__external_balances) do
      modify :balance, :decimal, scale: 2, precision: 10, null: false
    end
  end
end
