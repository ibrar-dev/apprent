defmodule AppCount.Repo.Migrations.AddRefsToRentApplications do
  use Ecto.Migration

  def change do
    alter table(:properties__tenants) do
      add :application_id, references(:rent_apply__rent_applications, on_delete: :nilify_all)
      remove :unit_id
    end

    alter table(:rent_apply__rent_applications) do
      add :admin_payment_id, references(:accounting__payments, on_delete: :nilify_all)
    end
  end
end