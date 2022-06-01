defmodule AppCount.Repo.Migrations.AddAdminToCardItem do
  use Ecto.Migration

  def change do
    alter table(:maintenance__card_items) do
      add :completed_by, :string
      add :status, :string
      add :confirmation, :jsonb
    end

    alter table(:maintenance__cards) do
      add :admin, :string
    end
  end
end
