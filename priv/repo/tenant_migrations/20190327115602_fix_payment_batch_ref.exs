defmodule AppCount.Repo.Migrations.FixPaymentBatchRef do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      remove :batch_id
      add :batch_id, references(:accounting__batches, on_delete: :nilify_all)
    end
  end
end
