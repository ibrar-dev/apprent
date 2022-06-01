defmodule AppCount.Repo.Migrations.AddMemosToDeposits do
  use Ecto.Migration

  def change do
    alter table(:accounting__batches) do
      add :memo, :text
    end
  end
end
