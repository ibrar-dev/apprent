defmodule AppCount.Repo.Migrations.AddAmountToChecks do
  use Ecto.Migration

  def change do
    alter table(:accounting__checks) do
      add :amount, :decimal, scale: 2, precision: 10
    end
  end
end
