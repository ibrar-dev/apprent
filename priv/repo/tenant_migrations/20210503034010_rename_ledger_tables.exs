defmodule AppCount.Repo.Migrations.RenameLedgerTables do
  use Ecto.Migration

  def change do
    rename table(:accounting__batches), to: table(:ledgers__batches)
    rename table(:accounting__payments), to: table(:ledgers__payments)
    rename table(:accounting__charges), to: table(:ledgers__charges)
    rename table(:accounting__customers), to: table(:ledgers__customer_ledgers)
    rename table(:accounting__charge_codes), to: table(:ledgers__charge_codes)

    alter table(:leasing__charges) do
      remove :charge_code_id
      add :charge_code_id, references(:ledgers__charge_codes, on_delete: :nothing), null: false
    end

    drop_if_exists table(:accounting__payment_nsfs)
    drop_if_exists table(:leasing__charge_codes)
  end
end
