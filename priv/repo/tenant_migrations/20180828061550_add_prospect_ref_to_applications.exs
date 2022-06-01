defmodule AppCount.Repo.Migrations.AddProspectRefToApplications do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__rent_applications) do
      add :prospect_id, references(:prospects__prospects, on_delete: :nilify_all)
    end
  end
end
