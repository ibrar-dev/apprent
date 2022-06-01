defmodule AppCount.Repo.Migrations.AddDateToAccountingCharges do
  use Ecto.Migration

  def change do
    alter table(:accounting__charges) do
      add :bill_date, :date
      modify :bill_ts, :integer, null: true
    end
    alter table(:properties__charges) do
      add :next_bill_date, :date
    end
  end
end
