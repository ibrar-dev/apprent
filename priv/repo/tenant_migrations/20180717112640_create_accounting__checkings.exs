defmodule AppCount.Repo.Migrations.CreateAccountingCheckings do
  use Ecto.Migration

  def change do
    create table(:accounting__checkings) do
      add :check_id, references(:accounting__checks, on_delete: :delete_all), null: false
      add :invoicing_id, references(:accounting__invoicings, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:accounting__checkings, [:check_id])
    create index(:accounting__checkings, [:invoicing_id])
  end
end
