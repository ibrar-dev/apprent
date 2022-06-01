defmodule AppCount.Repo.Migrations.DropSoftLedgerAccounts do
  use Ecto.Migration

  def change do
    drop table(:soft_ledger__accounts)
  end
end
