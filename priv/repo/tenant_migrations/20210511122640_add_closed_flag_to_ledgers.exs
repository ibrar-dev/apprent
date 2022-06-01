defmodule AppCount.Repo.Migrations.AddClosedFlagToLedgers do
  use Ecto.Migration

  def change do
    alter table(:ledgers__customer_ledgers) do
      add :closed, :boolean, null: false, default: false
    end
  end
end
