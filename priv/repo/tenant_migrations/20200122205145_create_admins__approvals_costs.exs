defmodule AppCount.Repo.Migrations.CreateAdminsApprovalsCosts do
  use Ecto.Migration

  def change do
    create table(:admins__approvals_costs) do
      add :amount, :decimal, default: 0, null: false
      add :approval_id, references(:admins__approvals, on_delete: :delete_all), null: false
      add :category_id, references(:accounting__categories, on_delete: :delete_all), null: false

      timestamps()
    end
    create index(:admins__approvals_costs, [:approval_id])
    create index(:admins__approvals_costs, [:category_id])
  end
end
