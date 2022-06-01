defmodule AppCount.Repo.Migrations.AddApprovedToAccountingPayees do
  use Ecto.Migration

  def change do
    alter table(:accounting__payees) do
      add :approved, :boolean, null: false, default: true
    end
  end
end
