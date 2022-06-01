defmodule AppCount.Repo.Migrations.AddBilledAtToCharges do
  use Ecto.Migration

  def change do
    alter table(:accounting__charges) do
      add :bill_ts, :integer, null: false
    end
  end
end
