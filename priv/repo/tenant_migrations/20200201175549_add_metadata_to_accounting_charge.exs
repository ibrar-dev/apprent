defmodule AppCount.Repo.Migrations.AddMetadataToAccountingCharge do
  use Ecto.Migration

  def change do
    alter table(:accounting__charges) do
      add :metadata, :jsonb, null: false, default: "{}"
    end
  end
end
