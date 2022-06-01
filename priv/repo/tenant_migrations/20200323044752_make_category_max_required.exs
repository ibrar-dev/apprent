defmodule AppCount.Repo.Migrations.MakeCategoryMaxRequired do
  use Ecto.Migration

  def change do
    alter table(:accounting__categories) do
      modify :max, :integer, null: false
    end
  end
end
