defmodule AppCount.Repo.Migrations.RestructureAccountCategories do
  use Ecto.Migration

  def change do
    execute "alter table #{prefix()}.accounting__account_categories rename constraint accounting__account_categories_pkey to accounting__categories_pkey"
    execute "ALTER SEQUENCE #{prefix()}.accounting__account_categories_id_seq RENAME TO accounting__categories_id_seq"
    rename table(:accounting__account_categories), to: table(:accounting__categories)
    rename table(:accounting__categories), :min, to: :num
    alter table(:accounting__categories) do
      modify :num, :integer, null: false
      remove :max
    end
    execute "alter index IF EXISTS #{prefix()}.accounting__account_categories_min_index rename to accounting__categories_num_index"
  end
end
