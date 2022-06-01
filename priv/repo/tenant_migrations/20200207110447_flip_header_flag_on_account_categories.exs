defmodule AppCount.Repo.Migrations.FlipHeaderFlagOnAccountCategories do
  use Ecto.Migration

  def change do
    alter table(:accounting__categories) do
      remove :header
      add :total_only, :boolean, null: false, default: false
    end
  end
end
