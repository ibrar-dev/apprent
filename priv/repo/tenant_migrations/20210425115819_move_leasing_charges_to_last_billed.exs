defmodule AppCount.Repo.Migrations.MoveLeasingChargesToLastBilled do
  use Ecto.Migration

  def change do
    alter table(:leasing__charges) do
      add :last_bill_date, :date
      remove :next_bill_date
    end
  end
end
