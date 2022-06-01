defmodule AppCount.Repo.Migrations.AddSignatureRefToLeases do
  use Ecto.Migration

  def change do
    alter table(:leases__leases) do
      add :bluemoon_signature_id, :string
      add :pending_bluemoon_signature_id, :string
      add :pending_bluemoon_lease_id, :string
    end
  end
end
