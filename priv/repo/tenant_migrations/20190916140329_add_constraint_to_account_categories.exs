defmodule AppCount.Repo.Migrations.AddConstraintToAccountCategories do
  use Ecto.Migration

  def change do
#    create unique_index(:accounting__account_categories, [:min])
    create constraint(:accounting__account_categories, :account_categories_min_max, check: "min < max")
  end
end
