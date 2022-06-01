defmodule AppCount.Repo.Migrations.AddTypeToAdminActions do
  use Ecto.Migration

  def change do
    alter table(:admins__actions) do
      add :type, :string, null: false, default: "create"
    end
  end
end
