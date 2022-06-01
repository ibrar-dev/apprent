defmodule AppCount.Repo.Migrations.AddIndexOnReceiptsTable do
  use Ecto.Migration

  def change do
    # although we already have unique indexes on these columns, apparently there are cases
    # where this is not enough and we get DB timeouts
    create index(:accounting__receipts, [:concession_id])
    create index(:accounting__receipts, [:charge_id])
    create index(:accounting__receipts, [:payment_id])
  end
end
