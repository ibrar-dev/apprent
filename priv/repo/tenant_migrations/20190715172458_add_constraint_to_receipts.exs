defmodule AppCount.Repo.Migrations.AddConstraintToReceipts do
  use Ecto.Migration

  def change do
    create constraint(:accounting__receipts, :only_one_source, check: "payment_id IS NULL OR concession_id IS NULL")
    create constraint(:accounting__receipts, :only_one_dest, check: "charge_id IS NULL OR account_id IS NULL")
  end
end
