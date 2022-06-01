defmodule AppCount.Repo.Migrations.CreatePayments do
  use Ecto.Migration

  def change do
    create table(:accounting__payments) do
      add :amount, :decimal, null: false
      add :transaction_id, :string, null: false
      add :source, :string, null: false
      add :surcharge, :decimal, null: false, default: 0
      add :response, :jsonb, default: "{}", null: false
      add :description, :text, default: "", null: false
      add :charge_id, references(:accounting__charges, on_delete: :nilify_all)
      add :tenant_id, references(:properties__tenants, on_delete: :nilify_all)

      timestamps()
    end

    create index(:accounting__payments, [:charge_id])
    create index(:accounting__payments, [:tenant_id])
  end
end
