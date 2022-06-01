defmodule AppCount.Repo.Migrations.FixConstraintsForAccountCatgories do
  use Ecto.Migration

  def change do
    alter table(:accounting__account_categories) do
      remove :path
    end
    drop_if_exists unique_index(:accounting__account_categories, [:name])
    create unique_index(:accounting__account_categories, [:min])
    create unique_index(:accounting__account_categories, [:max])
  end
end
