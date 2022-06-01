defmodule AppCount.Repo.Migrations.CreatePropertiesRecurringLetters do
  use Ecto.Migration

  def change do
    create table(:properties__recurring_letters) do
      add :letter_template_id, references(:properties__letter_templates, on_delete: :delete_all), null: false
      add :admin_id, references(:admins__admins, on_delete: :delete_all), null: false
      add :resident_params, :jsonb, null: false, default: "{}"
      add :schedule, :json, null: false, default: "{}"
      add :active, :boolean, null: false, default: false
      add :last_run, :integer
      add :next_run, :integer
      add :notify, :boolean, null: false
      add :visible, :boolean, null: false
      add :name, :string, null: false

      timestamps()
    end

    create index(:properties__recurring_letters, [:letter_template_id])
  end
end
