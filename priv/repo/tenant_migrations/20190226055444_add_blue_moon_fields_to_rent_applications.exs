defmodule AppCount.Repo.Migrations.AddBlueMoonFieldsToRentApplications do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__leases) do
      add :lease_id, :string
      add :signature_id, :string
    end
  end
end
