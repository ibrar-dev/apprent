defmodule AppCount.Repo.Migrations.CreateVendorsNotes do
  use Ecto.Migration

  def change do
    create table(:vendors__notes) do
      add :text, :text
      add :image, :string
      add :order_id, references(:vendors__orders, on_delete: :delete_all)
      add :tenant_id, references(:properties__tenants, on_delete: :nothing)
      add :admin_id, references(:admins__admins, on_delete: :nothing)
      add :tech_id, references(:maintenance__techs, on_delete: :nothing)
      add :vendor_id, references(:vendors__vendors, on_delete: :nothing)

      timestamps()
    end

  end
end
