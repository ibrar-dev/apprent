defmodule AppCount.Repo.Migrations.AddCardItemsIndex do
  use Ecto.Migration

  def change do
    create index("maintenance__card_items", [:card_id])
    create index("maintenance__card_items", [:vendor_id])
  end
end
