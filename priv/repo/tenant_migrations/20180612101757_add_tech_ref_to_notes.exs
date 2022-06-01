defmodule AppCount.Repo.Migrations.AddTechRefToNotes do
  use Ecto.Migration

  def change do
    alter table(:maintenance__notes) do
      add :tech_id, references(:maintenance__techs, on_delete: :delete_all)
    end

    drop constraint(:maintenance__notes, :must_have_assigner)
    create constraint(
             :maintenance__notes,
             :must_have_assigner,
             check: "admin_id IS NOT NULL OR tenant_id IS NOT NULL OR tech_id IS NOT NULL"
           )
    create index(:maintenance__notes, [:tech_id])
  end
end
