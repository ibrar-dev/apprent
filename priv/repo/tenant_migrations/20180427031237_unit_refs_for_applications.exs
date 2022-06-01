defmodule AppCount.Repo.Migrations.UnitRefsForApplications do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__move_ins) do
      add :unit_id, references(:properties__units, on_delete: :nilify_all)
    end
  end
end
