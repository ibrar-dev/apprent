defmodule AppCount.Repo.Migrations.AddDeviceRefToApplications do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__rent_applications) do
      add :device_id, references(:admins__devices, on_delete: :nilify_all)
    end

    create index(:rent_apply__rent_applications, [:device_id])
    create index(:rent_apply__rent_applications, [:admin_payment_id])
  end
end
