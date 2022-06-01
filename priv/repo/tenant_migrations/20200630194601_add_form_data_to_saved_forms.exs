defmodule AppCount.Repo.Migrations.AddFormDataToSavedForms do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__saved_forms) do
      add(:form_summary, :jsonb, default: "{}")
      add(:name, :string, null: true)
      add(:lang, :string, null: true)
      add(:start_time, :utc_datetime, null: true)
    end
  end
end
