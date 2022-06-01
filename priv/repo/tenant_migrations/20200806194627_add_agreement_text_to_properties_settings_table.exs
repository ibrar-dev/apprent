defmodule AppCount.Repo.Migrations.AddAgreementTextToPropertiesSettingsTable do
  use Ecto.Migration

  def change do
    alter table("properties__settings") do
      add :agreement_text, :text, default: "", null: true
    end
  end
end
