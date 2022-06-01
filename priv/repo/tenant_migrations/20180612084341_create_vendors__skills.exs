defmodule AppCount.Repo.Migrations.CreateVendorsSkills do
  use Ecto.Migration

  def change do
    create table(:vendors__skills) do
      add :vendor_id, :integer
      add :category_id, :integer

      timestamps()
    end

    create unique_index(:vendors__skills, [:vendor_id, :category_id])

  end
end
