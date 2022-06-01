defmodule AppCount.Repo.Migrations.FixReceiptConstraint do
  use Ecto.Migration

  def change do
    drop constraint(:accounting__receipts, :valid_date_range)
    create constraint(:accounting__receipts, :valid_date_range, check: "start_date < stop_date")
  end
end
