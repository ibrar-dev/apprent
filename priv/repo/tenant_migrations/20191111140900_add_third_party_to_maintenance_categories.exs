defmodule AppCount.Repo.Migrations.AddThirdPartyToMaintenanceCategories do
  use Ecto.Migration

  def change do
    alter table(:maintenance__categories) do
      add :third_party, :boolean, default: false, null: true
    end
  end
end
