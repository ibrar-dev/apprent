defmodule AppCount.Repo.Migrations.FixRequiredFieldsForDocuments do
  use Ecto.Migration

  def change do
    alter table(:properties__documents) do
      modify :url, :string, null: true
    end
    create index(:properties__documents, [:document_id])
    create index(:accounting__invoices, [:document_id])
    create index(:properties__properties, [:logo_id])
    create index(:properties__properties, [:icon_id])
    create index(:properties__properties, [:banner_id])
    create index(:rewards__types, [:icon_id])
    create index(:rewards__prizes, [:icon_id])
    create index(:accounting__payment_nsfs, [:proof_id])
    create index(:maintenance__techs, [:image_id])
    create index(:properties__resident_events, [:attachment_id])
    create index(:properties__resident_events, [:image_id])
    create index(:properties__leases, [:document_id])
    create index(:accounting__payments, [:image_id])
    create index(:messaging__emails, [:body_id])
    create index(:materials__stocks, [:image_id])
    create index(:materials__materials, [:image_id])
    create index(:materials__warehouses, [:image_id])
    create index(:accounts__accounts, [:profile_pic_id])
  end
end
