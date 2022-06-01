defmodule AppCount.Repo.Migrations.MakeCheckAmountRequired do
  use Ecto.Migration

  def change do
    alter table(:accounting__checks) do
      modify :amount, :decimal, scale: 2, precision: 10, null: false
    end
  end
end
