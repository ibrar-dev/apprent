defmodule AppCount.Repo.Migrations.AddCompletionAndHideToCard do
  use Ecto.Migration

  def change do
    alter table(:maintenance__cards) do
      add :hidden, :boolean, default: false
      add :completion, :jsonb
    end
  end
end
