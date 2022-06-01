defmodule AppCount.Repo.Migrations.AddParamsToChecks do
  use Ecto.Migration

  def change do
    alter table(:accounting__checks) do
      add :document_id, references(:data__uploads, on_delete: :nilify_all)
      add :amount_lang, :string
    end
  end
end
