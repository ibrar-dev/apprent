defmodule AppCount.Repo.Migrations.MakeReadyOrderFields do
  use Ecto.Migration

  def change do
    alter table(:maintenance__orders) do
      add :card_item_id, references(:maintenance__card_items, on_delete: :delete_all)
    end

    create unique_index(:maintenance__orders, [:card_item_id])

    alter table(:maintenance__categories) do
      add :visible, :boolean, null: false, default: true
    end
  end
end
