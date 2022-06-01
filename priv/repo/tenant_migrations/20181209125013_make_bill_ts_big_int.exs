defmodule AppCount.Repo.Migrations.MakeBillTsBigInt do
  use Ecto.Migration

  def change do
    alter table(:accounting__charges) do
      modify :bill_ts, :bigint
    end

    alter table(:properties__charges) do
      modify :next_bill, :bigint
      modify :account_id, :bigint
    end

    create index(:properties__packages, [:tenant_id])
  end
end
