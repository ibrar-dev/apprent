defmodule AppCount.Repo.Migrations.CreateAccountsBank do
  use Ecto.Migration

  def change do
    create table(:accounts__banks) do
      add :routing, :string, null: false
      add :name, :string, null: false

      timestamps()
    end

    create unique_index(:accounts__banks, [:routing])
  end
end
