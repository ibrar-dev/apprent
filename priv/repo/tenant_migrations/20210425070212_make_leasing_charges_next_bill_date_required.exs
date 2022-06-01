defmodule AppCount.Repo.Migrations.MakeLeasingChargesNextBillDateRequired do
  use Ecto.Migration

  def change do
    alter table(:leasing__charges) do
      modify :next_bill_date, :date, null: false
    end
  end
end
