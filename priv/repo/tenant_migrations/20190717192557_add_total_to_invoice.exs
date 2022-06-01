defmodule AppCount.Repo.Migrations.AddTotalToInvoice do
  use Ecto.Migration

  def change do
    alter table(:accounting__invoices) do
      add :amount, :decimal, null: true
    end

    alter table(:properties__settings) do
      add :renewal_overage_threshold, :integer, default: 25, null: false
    end
  end
end
