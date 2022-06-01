defmodule AppCount.Repo.Migrations.CreateVendorsCategories do
  use Ecto.Migration

  def change do
    create table(:vendors__categories) do
      add :name, :string

      timestamps()
    end

  end
end
