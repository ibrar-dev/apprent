defmodule AppCount.Repo.Migrations.RemovePurchasesTables do
  use Ecto.Migration

  def change do
      execute("DROP TABLE #{prefix()}.purchases__admin_permissions, #{prefix()}.purchases__items, #{prefix()}.purchases__line_items, #{prefix()}.purchases__purchase_order_projects, #{prefix()}.purchases__purchase_order_rules, #{prefix()}.purchases__purchase_orders, #{prefix()}.purchases__status_log CASCADE")
  end
end
