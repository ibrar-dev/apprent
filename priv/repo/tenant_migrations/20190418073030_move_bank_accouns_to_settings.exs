defmodule AppCount.Repo.Migrations.MoveBankAccounsToSettings do
  use Ecto.Migration

  def change do
    rename table(:accounts__banks), to: table(:settings__banks)
  end
end
