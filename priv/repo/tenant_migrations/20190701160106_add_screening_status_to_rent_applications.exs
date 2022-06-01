defmodule AppCount.Repo.Migrations.AddScreeningStatusToRentApplications do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__rent_applications) do
      add :is_conditional, :boolean, default: false, null: false
    end
  end
end
