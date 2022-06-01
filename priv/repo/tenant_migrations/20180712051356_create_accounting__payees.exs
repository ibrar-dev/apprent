defmodule AppCount.Repo.Migrations.CreateAccountingPayees do
  use Ecto.Migration

  def change do
    create table(:accounting__payees) do
      add :name, :string, null: false
      add :address, :map, null: false, default: "{}"

      timestamps()
    end

  end
end
