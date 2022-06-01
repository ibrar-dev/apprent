defmodule AppCount.Repo.Migrations.RemoveUniqueConstraintForCharges do
  use Ecto.Migration

  def change do
    drop unique_index(:accounting__charges, [:lease_id, :bill_date, :account_id, :status])
  end
end
