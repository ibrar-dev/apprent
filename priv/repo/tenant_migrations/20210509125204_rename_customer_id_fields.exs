defmodule AppCount.Repo.Migrations.RenameCustomerIdFields do
  use Ecto.Migration

  def change do
    rename table(:ledgers__payments), :customer_id, to: :customer_ledger_id
    rename table(:ledgers__charges), :customer_id, to: :customer_ledger_id
    rename table(:leasing__leases), :customer_id, to: :customer_ledger_id
    rename table(:tenants__tenancies), :customer_id, to: :customer_ledger_id
  end
end
