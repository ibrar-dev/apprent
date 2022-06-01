defmodule AppCount.Repo.Migrations.CreateSocialBlocks do
  use Ecto.Migration

  def change do
    create table(:social__blocks) do
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all)
      add :blockee_id, :bigint, null: false

      timestamps()
    end
  end
end
