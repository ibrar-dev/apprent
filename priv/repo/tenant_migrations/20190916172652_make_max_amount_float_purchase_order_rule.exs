defmodule AppCount.Repo.Migrations.MakeMaxAmountFloatPurchaseOrderRule do
  use Ecto.Migration

  def change do
    alter table(:purchases__purchase_order_rules) do
      remove :max_amount
      add :max_amount, :float
    end
  end
end
