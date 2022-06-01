defmodule AppCount.Repo.Migrations.AddApplicationRefToPayments do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      add :application_id, references(:rent_apply__rent_applications, on_delete: :delete_all)
    end
  end
end
