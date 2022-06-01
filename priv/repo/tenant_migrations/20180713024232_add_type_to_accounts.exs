defmodule AppCount.Repo.Migrations.AddTypeToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounting__accounts) do
      add :type, :string, null: false, default: "charge"
    end
  end
end
