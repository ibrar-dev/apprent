defmodule AppCount.Repo.Migrations.AddEmailedToAssignment do
  use Ecto.Migration

  def change do
    alter table(:maintenance__assignments) do
      add :email, :jsonb
    end

    alter table(:vendors__vendors) do
      add :contact_name, :string
    end

    alter table(:properties__units) do
      add :address, :jsonb
    end
  end
end
