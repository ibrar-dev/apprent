defmodule AppCount.Repo.Migrations.AddMissingIndexToCustomers do
  use Ecto.Migration

  def change do
    create index(:accounting__customers, [:property_id])
    create index(:accounting__payments, [:customer_id])
    create index(:accounting__charges, [:customer_id])
  end
end
