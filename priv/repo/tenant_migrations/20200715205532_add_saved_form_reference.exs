defmodule AppCount.Repo.Migrations.AddSavedFormReference do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__rent_applications) do
      add :saved_form_id, references(:rent_apply__saved_forms, on_delete: :nilify_all)
    end
  end
end
