defmodule AppCount.Repo.Migrations.ChangeChargeAssoc do
  use Ecto.Migration

  def change do
    alter table(:accounting__charges) do
      remove :account_id, references(:accounting__accounts, on_delete: :nothing), null: false
      add :charge_code_id, references(:accounting__charge_codes, on_delete: :nothing), null: false
    end
    alter table(:properties__charges) do
      remove :account_id, references(:accounting__accounts, on_delete: :nothing), null: false
      add :charge_code_id, references(:accounting__charge_codes, on_delete: :nothing), null: false
    end
    alter table(:units__default_lease_charges) do
      remove :account_id, references(:accounting__accounts, on_delete: :nothing)
      add :charge_code_id, references(:accounting__charge_codes, on_delete: :delete_all)
    end

    create index(:accounting__charges, [:charge_code_id])
    create index(:properties__charges, [:charge_code_id])
    create index(:units__default_lease_charges, [:charge_code_id])
  end
end
