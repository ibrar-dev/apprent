defmodule AppCount.Repo.Migrations.ChangeLineHistorytype do
  use Ecto.Migration

  def change do
    alter table(:accounting__budgets__lines) do
      remove :history, :jsonb
      add :history, :jsonb, default: "[]", null: false
    end
  end
end
