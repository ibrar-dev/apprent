defmodule AppCount.Repo.Migrations.AddExternalIdsToLeasingLeases do
  use Ecto.Migration

  def change do
    alter table(:leasing__leases) do
      add :external_id, :string
      add :external_signature_id, :string
      add :pending_external_id, :string
      add :pending_external_signature_id, :string
    end
  end
end
