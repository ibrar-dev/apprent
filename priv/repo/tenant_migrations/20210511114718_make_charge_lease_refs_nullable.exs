defmodule AppCount.Repo.Migrations.MakeChargeLeaseRefsNullable do
  use Ecto.Migration

  def change do
    alter table(:ledgers__charges) do
      modify :lease_id, :bigint, null: true
    end
  end
end
