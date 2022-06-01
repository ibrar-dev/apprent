defmodule AppCount.Repo.Migrations.DynamicReceipts do
  use Ecto.Migration

  def change do
    alter table(:accounting__receipts) do
      add :start_date, :date
      add :stop_date, :date
    end

    drop unique_index(:accounting__receipts, [:charge_id, :concession_id])
    create unique_index(
             :accounting__receipts,
             [:charge_id, :concession_id, :start_date, :stop_date],
             name: :accounting__receipts_charge_id_concession_id_index
           )
    drop unique_index(:accounting__receipts, [:charge_id, :payment_id])
    create unique_index(
             :accounting__receipts,
             [:charge_id, :payment_id, :start_date, :stop_date],
             name: :accounting__receipts_charge_id_payment_id_index
           )
    create constraint(:accounting__receipts, :valid_date_range, check: "start_date > stop_date")
  end
end
