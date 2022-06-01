defmodule AppCount.Repo.Migrations.ChangeReversedStatus do
  use Ecto.Migration

  def change do
    alter table(:accounting__charges) do
      add :reversal_id, references(:accounting__charges, on_delete: :nilify_all)
    end

    create index(:accounting__charges, [:reversal_id])
  end
end
