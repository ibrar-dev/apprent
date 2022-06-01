defmodule AppCount.Repo.Migrations.AddPayeeToAssignmentsAndAttachmentToNote do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE #{prefix()}.maintenance__assignments DROP CONSTRAINT maintenance__assignments_tech_id_fkey"
    alter table(:maintenance__assignments) do
      modify :tech_id, references(:maintenance__techs, on_delete: :delete_all), null: true
      add :payee_id, references(:accounting__payees, on_delete: :nilify_all), null: true
    end

    alter table(:maintenance__notes) do
      add :attachment_id, references(:data__uploads, on_delete: :nilify_all), null: true
    end
  end

  def down do
    execute "ALTER TABLE #{prefix()}.maintenance__assignments DROP CONSTRAINT maintenance__assignments_tech_id_fkey"
    alter table(:maintenance__notes) do
      remove :attachment_id
    end

    alter table(:maintenance__assignments) do
      remove :payee_id
      modify :tech_id, references(:maintenance__techs, on_delete: :delete_all), null: false
    end
  end
end
