defmodule AppCount.Repo.Migrations.AddCustomerIdsToChargesAndPayments do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      add :customer_id, references(:accounting__customers, on_delete: :nothing)
    end

    alter table(:accounting__charges) do
      add :customer_id, references(:accounting__customers, on_delete: :nothing)
    end
  end
end
