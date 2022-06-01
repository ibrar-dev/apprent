defmodule AppCount.Repo.Migrations.AddPersonRefToEmployments do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__employments) do
      add :person_id, references(:rent_apply__persons, on_delete: :delete_all)
    end

    create index(:rent_apply__employments, :person_id)
  end
end
