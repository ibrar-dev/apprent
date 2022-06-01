defmodule AppCount.Repo.Migrations.CreateVendorsVendors do
  use Ecto.Migration

  def change do
    create table(:vendors__vendors) do
      add :name, :string
      add :phone, :string
      add :email, :string
      add :address, :string

      timestamps()
    end

  end
end
