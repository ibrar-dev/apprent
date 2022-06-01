defmodule AppCount.Repo.Migrations.CreateAccountingReconciliations do
  use Ecto.Migration

  def change do
    create table(:accounting__reconciliations) do
      add :clear_date, :date
      add :memo, :string
      add :payment_id, references(:accounting__payments)
      add :check_id, references(:accounting__checks)
      add :batch_id, references(:accounting__batches)

      timestamps()
    end
  end

end
