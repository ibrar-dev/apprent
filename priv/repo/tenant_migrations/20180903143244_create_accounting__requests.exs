defmodule AppCount.Repo.Migrations.CreateAccountingRequests do
  use Ecto.Migration

  def change do
    create table(:accounting__requests) do
      add :content, :text, null: false
      add :pending, :boolean, default: true, null: false
      add :details, :jsonb, null: false, default: "{}"
      add :payment_id, references(:accounting__payments, on_delete: :nilify_all)
      add :charge_id, references(:accounting__charges, on_delete: :nilify_all)
      add :admin_id, references(:admins__admins, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:accounting__requests, [:admin_id, :charge_id])
    create unique_index(:accounting__requests, [:admin_id, :payment_id])
  end
end
