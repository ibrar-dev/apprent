defmodule AppCount.Repo.Migrations.CreateSocialPosts do
  use Ecto.Migration

  def change do
    create table(:social__posts) do
      add :text, :text
      add :history, :jsonb, null: true
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all)

      timestamps()
    end
  end
end
