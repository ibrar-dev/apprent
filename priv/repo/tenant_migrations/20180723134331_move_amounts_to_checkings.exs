defmodule AppCount.Repo.Migrations.MoveAmountsToCheckings do
  use Ecto.Migration

  def change do
    alter table(:accounting__checks) do
      remove :amount
    end

    alter table(:accounting__checkings) do
      add :amount, :decimal, null: false
    end
  end
end
