defmodule AppCount.Repo.Migrations.AddExternalIdToPayments do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      add :external_id, :string
    end
    create unique_index(:accounting__payments, [:external_id])
  end
end
