defmodule AppCount.Repo.Migrations.RemoveTotalAccountField do
  use Ecto.Migration

  def change do
    alter table(:accounting__accounts) do
      remove :total_account
    end
  end
end
