defmodule AppCount.Repo.Migrations.AddEditNotesToPayments do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      add :edits, :jsonb, default: "[]", null: false
    end
  end
end
