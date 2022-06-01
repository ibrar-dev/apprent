defmodule AppCount.Repo.Migrations.AddPaymentIdToApplications do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__rent_applications) do
      add :payment_id, references(:accounting__payments, on_delete: :nilify_all)
    end

    create index(:rent_apply__rent_applications, [:payment_id])
  end
end
