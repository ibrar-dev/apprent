defmodule AppCount.Repo.Migrations.AddConstraintToPoRules do
  use Ecto.Migration

  def change do
    alter table(:purchases__purchase_order_rules) do
      remove :admin_id
      add :admin_permission_id, references(:purchases__admin_permissions)
    end

    create unique_index(:purchases__purchase_order_rules, [:admin_permission_id, :item_id, :property_id, :vendor_id, :max_amount])
  end
end
