defmodule AppCount.Repo.Migrations.UnifyAccountsTable do
  use Ecto.Migration

  def change do
    alter table(:accounting__accounts) do
      add :is_credit, :boolean, default: true, null: false
      add :is_balance, :boolean, default: true, null: false
      add :is_cash, :boolean, default: false, null: false
      add :is_payable, :boolean, default: false, null: false
      remove :type
    end

    alter table(:accounting__bank_accounts) do
      modify :cash_account_id,
             references(:accounting__accounts, on_delete: :delete_all),
             null: false,
             from: references(:accounting__cash_accounts, on_delete: :delete_all)
    end

    rename table(:accounting__bank_accounts), :cash_account_id, to: :account_id

    alter table(:accounting__invoices) do
      modify :cash_account_id,
             references(:accounting__accounts, on_delete: :delete_all),
             null: false,
             from: references(:accounting__cash_accounts, on_delete: :delete_all)
    end

    rename table(:accounting__invoices), :cash_account_id, to: :account_id

    alter table(:accounting__registers) do
      modify :cash_account_id,
             references(:accounting__accounts, on_delete: :delete_all),
             null: false,
             from: references(:accounting__cash_accounts, on_delete: :delete_all)
    end

    rename table(:accounting__registers), :cash_account_id, to: :account_id

    drop table(:accounting__cash_accounts)
  end
end
