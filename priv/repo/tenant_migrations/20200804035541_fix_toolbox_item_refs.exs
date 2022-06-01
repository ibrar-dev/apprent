defmodule AppCount.Repo.Migrations.FixToolboxItemRefs do
  use Ecto.Migration

  def change do
    drop constraint(:materials__toolbox_items, :materials__toolbox_items_assignment_id_fkey)

    alter table(:materials__toolbox_items) do
      modify :assignment_id, references(:maintenance__assignments, on_delete: :delete_all)
    end
  end
end
