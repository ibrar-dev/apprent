defmodule AppCount.Repo.Migrations.AddDbConstraintsToFinanceAccounts do
  use Ecto.Migration

  def change do
    create unique_index(:finance__accounts, [:name])
    create unique_index(:finance__accounts, [:number])
  end
end
