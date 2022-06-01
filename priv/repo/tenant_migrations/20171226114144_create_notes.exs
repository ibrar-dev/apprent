defmodule AppCount.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:maintenance__notes) do
      add :text, :text
      add :image, :string
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all)
      add :admin_id, references(:admins__admins, on_delete: :delete_all)
      add :order_id, references(:maintenance__orders, on_delete: :delete_all), null: false

      timestamps()
    end

    create constraint(:maintenance__notes, :must_have_body, check: "text IS NOT NULL OR image IS NOT NULL")
    create constraint(:maintenance__notes, :must_have_assigner, check: "admin_id IS NOT NULL OR tenant_id IS NOT NULL")
    create index(:maintenance__notes, [:order_id])
    create index(:maintenance__notes, [:admin_id])
    create index(:maintenance__notes, [:tenant_id])
  end
end
