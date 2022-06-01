defmodule AppCount.Repo.Migrations.EvenMoreIndexFixes do
  use Ecto.Migration

  def change do
    execute "alter index IF EXISTS #{prefix()}.accounts__purchases_prize_id_index rename to rewards__purchases_prize_id_index"
    execute "alter index IF EXISTS #{prefix()}.maintenance__stocks_name_index rename to materials__stocks_name_index"
    execute "alter index IF EXISTS #{prefix()}.maintenance__material_types_name_index rename to materials__material_types_name_index"

  end
end
