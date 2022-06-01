defmodule AppCount.Repo.Migrations.AddUploadRefToSchemas do
  use Ecto.Migration

  def change do
    alter table(:accounting__invoices) do
      add :document_id, references(:data__uploads, on_delete: :nilify_all)
    end
    alter table(:admins__profiles) do
      add :image_id, references(:data__uploads, on_delete: :nilify_all)
    end
    alter table(:rewards__types) do
      add :icon_id, references(:data__uploads, on_delete: :nilify_all)
    end
    alter table(:materials__materials) do
      add :image_id, references(:data__uploads, on_delete: :nilify_all)
    end
    alter table(:accounts__accounts) do
      add :profile_pic_id, references(:data__uploads, on_delete: :nilify_all)
    end
    alter table(:rewards__prizes) do
      add :icon_id, references(:data__uploads, on_delete: :nilify_all)
    end
    alter table(:materials__warehouses) do
      add :image_id, references(:data__uploads, on_delete: :nilify_all)
    end
    alter table(:materials__stocks) do
      add :image_id, references(:data__uploads, on_delete: :nilify_all)
    end
    alter table(:messaging__emails) do
      add :body_id, references(:data__uploads, on_delete: :nilify_all)
    end
    alter table(:accounting__payments) do
      add :image_id, references(:data__uploads, on_delete: :nilify_all)
    end
    alter table(:properties__properties) do
      add :logo_id, references(:data__uploads, on_delete: :nilify_all)
      add :icon_id, references(:data__uploads, on_delete: :nilify_all)
      add :banner_id, references(:data__uploads, on_delete: :nilify_all)
    end
    alter table(:properties__documents) do
      add :document_id, references(:data__uploads, on_delete: :nilify_all)
    end
    alter table(:properties__leases) do
      add :document_id, references(:data__uploads, on_delete: :nilify_all)
    end
    alter table(:properties__resident_events) do
      add :attachment_id, references(:data__uploads, on_delete: :nilify_all)
      add :image_id, references(:data__uploads, on_delete: :nilify_all)
    end
    alter table(:maintenance__techs) do
      add :image_id, references(:data__uploads, on_delete: :nilify_all)
    end
    alter table(:accounting__payment_nsfs) do
      add :proof_id, references(:data__uploads, on_delete: :nilify_all)
    end
  end
end
