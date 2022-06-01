defmodule AppCount.Repo.Migrations.AddImageAttachmentToCharges do
  use Ecto.Migration

  def change do
    alter table(:accounting__charges) do
      add :image_id, references(:data__uploads, on_delete: :nilify_all)
      add :nsf_id, references(:accounting__payments, on_delete: :delete_all)
    end

    create index(:accounting__charges, [:image_id])
    create unique_index(:accounting__charges, [:nsf_id])
  end
end
