defmodule AppCount.Repo.Migrations.MakeNextBillRequired do
  use Ecto.Migration

  def change do
    alter table(:properties__charges) do
      modify :next_bill_date, :date, null: false
    end
  end
end
