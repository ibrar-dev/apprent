defmodule AppCount.Repo.Migrations.AddSettingsToPropertySettings do
  use Ecto.Migration

  def change do
    alter table(:properties__settings) do
      add :applicant_info_visible, :boolean, null: false, default: true
      add :accepts_partial_payments, :boolean, null: false, default: true
      add :instant_screen, :boolean, null: false, default: false
    end
  end
end
