defmodule AppCount.Repo.Migrations.CreateSocialPostsLikes do
  use Ecto.Migration

  def change do
    create table(:social__posts_likes) do
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all)
      add :post_id, references(:social__posts, on_delete: :delete_all)

      timestamps()
    end

    alter table(:social__posts) do
      add :property_id, references(:properties__properties, on_delete: :delete_all)
    end

    create unique_index(:social__posts_likes, [:post_id, :tenant_id])
  end
end
