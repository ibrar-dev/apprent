defmodule AppCount.Repo.Migrations.AddsLocationUnderscoreId do
  use Ecto.Migration

  def change do
    alter table("soft_ledger__locations") do
      add :underscore_id, :integer
    end
  end
end
