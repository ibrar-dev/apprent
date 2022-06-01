defmodule AppCount.Repo.Migrations.AddMissingFKIndiciesForPayments do
  use Ecto.Migration

  def change do
    create index(:accounting__payments, [:property_id])
    create index(:accounting__payments, [:batch_id])
  end
end
