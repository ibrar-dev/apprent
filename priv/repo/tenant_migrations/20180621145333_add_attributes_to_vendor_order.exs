defmodule AppCount.Repo.Migrations.AddAttributesToVendorOrder do
  use Ecto.Migration

  def change do
    alter table(:vendors__orders) do
      add :uuid, :uuid
      add :unit_id, references(:properties__units, on_delete: :delete_all)
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all)
      add :card_item_id, references(:maintenance__card_items, on_delete: :delete_all)
      add :priority, :integer, null: false, default: 0
      add :ticket, :string, null: false, default: "UNKNOWN"

      remove :order_id
    end
  end
end
