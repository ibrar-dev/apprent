defmodule AppCount.Repo.Migrations.AddHistoryFieldToSocialPosts do
  use Ecto.Migration

  def change do
    alter table(:social__posts) do
      add :visible, :boolean, default: true, null: false
    end
  end
end
