defmodule AppCount.Repo.Migrations.CreateAdminsEmailSubscriptions do
  use Ecto.Migration

  def change do
    create table(:admins__email_subscriptions) do
      add :admin_id, references(:admins__admins, on_delete: :delete_all), null: false
      add :trigger, :string, null: false
      add :active, :boolean, null: false, default: true

      timestamps()
    end

    create index(:admins__email_subscriptions, [:admin_id])
    create unique_index(:admins__email_subscriptions, [:admin_id, :trigger])
  end
end
