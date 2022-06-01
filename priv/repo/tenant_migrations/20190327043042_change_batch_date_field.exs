defmodule AppCount.Repo.Migrations.ChangeBatchDateField do
  use Ecto.Migration

  def change do
    alter table(:accounting__batches) do
      remove :date
      add :date_closed, :date
      remove :closed
    end
  end
end
