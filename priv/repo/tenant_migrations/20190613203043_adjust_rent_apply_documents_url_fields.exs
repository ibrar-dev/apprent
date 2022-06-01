defmodule AppCount.Repo.Migrations.AdjustRentApplyDocumentsUrlFields do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__documents) do
      remove :url
      modify :url_id, :bigint, null: false
    end
  end
end
