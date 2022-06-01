defmodule AppCount.Repo.Migrations.AddPublicRefsToTenantTables do
  use Ecto.Migration

  def change do
    alter table(:admins__admins) do
      add :public_user_id, references(:users, on_delete: :nothing, prefix: "public")
    end

    alter table(:accounts__accounts) do
      add :public_user_id, references(:users, on_delete: :nothing, prefix: "public")
    end

    alter table(:properties__properties) do
      add :public_property_id, references(:properties, on_delete: :nothing, prefix: "public")
    end

    alter table(:maintenance__techs) do
      add :public_user_id, references(:users, on_delete: :nothing, prefix: "public")
    end

    create unique_index(:admins__admins, [:public_user_id])
    create unique_index(:maintenance__techs, [:public_user_id])
    create unique_index(:accounts__accounts, [:public_user_id])
    create unique_index(:properties__properties, [:public_property_id])
  end
end
