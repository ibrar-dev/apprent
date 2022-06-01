defmodule AppCount.Repo.Migrations.MakeLeasingLeasesDocumentIdNullable do
  use Ecto.Migration

  def change do
    alter table(:leasing__leases) do
      modify :document_id, :bigint, null: true
    end
  end
end
