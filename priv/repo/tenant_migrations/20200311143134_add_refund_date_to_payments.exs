defmodule AppCount.Repo.Migrations.AddRefundDateToPayments do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      add :refund_date, :date
    end
  end
end
