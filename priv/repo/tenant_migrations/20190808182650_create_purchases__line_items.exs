defmodule AppCount.Repo.Migrations.CreatePurchasesLineItems do
  use Ecto.Migration

  def change do
    create table(:purchases__items) do
      add :name, :string, null: false
      add :account_id, references(:accounting__accounts ), null: false
      add :price, :decimal, null: false
      timestamps()
    end

    create table(:purchases__line_items) do
      add :item_id, references(:purchases__items ), null: false
      add :quantity, :integer
      add :total, :decimal
      add :price, :decimal
      add :purchase_order_id,  references(:purchases__purchase_orders), null: false, on_delete: :delete_all
      add :note, :string
      add :document_id, references(:data__uploads, on_delete: :delete_all)

      timestamps()
    end

    create constraint(:purchases__items, :price_positive, check: "price > 0")
    create constraint(:purchases__line_items, :quantity_positive, check: "quantity > 0")

  end
end
