defmodule AppCount.Repo.Migrations.RenameAccountsChargeCodeColumn do
  use Ecto.Migration

  def change do
    drop_if_exists unique_index(:accounting__accounts, [:charge_code])
    rename table(:accounting__accounts), :charge_code, to: :description
  end
end
