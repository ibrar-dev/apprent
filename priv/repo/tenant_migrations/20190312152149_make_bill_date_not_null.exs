defmodule AppCount.Repo.Migrations.MakeBillDateNotNull do
  use Ecto.Migration

  def change do
    alter table(:accounting__charges) do
      modify :bill_date, :date, null: false
      remove :bill_ts
    end

    alter table(:properties__charges) do
      remove :next_bill
    end
  end
end
