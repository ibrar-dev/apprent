defmodule AppCount.Repo.Migrations.AddBatchIdToPayments do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      add :batch_id, references(:accounting__batches, on_delete: :nothing)
    end
  end
end
