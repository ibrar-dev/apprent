defmodule AppCount.Repo.Migrations.AttachApplicationToLedger do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__rent_applications) do
      add :customer_ledger_id, references(:ledgers__customer_ledgers, on_delete: :nothing)
      remove :security_deposit_id
    end

    create index(:rent_apply__rent_applications, [:prospect_id])
    create index(:rent_apply__rent_applications, [:saved_form_id])
  end
end
