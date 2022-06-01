defmodule AppCount.Repo.Migrations.AddItemIdAndPurchaseOrderIdToInvoice do
  use Ecto.Migration

  def change do
     alter table(:accounting__invoices) do
       add :purchase_order_id, references(:purchases__purchase_orders)
     end

     alter table(:accounting__invoicings) do
       add :item_id, references(:purchases__items)
     end
  end
end
