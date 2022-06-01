defmodule AppCount.Repo.Migrations.AddHeaderFlagToAccountCategories do
  use Ecto.Migration

  def change do
    alter table(:accounting__categories) do
      add :header, :boolean, default: true, null: false
    end
  end
end
