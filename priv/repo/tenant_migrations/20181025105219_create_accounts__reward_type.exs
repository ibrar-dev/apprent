defmodule AppCount.Repo.Migrations.CreateAccountsRewardType do
  use Ecto.Migration

  def change do
    create table(:accounts__reward_types) do
      add :name, :string, null: false
      add :icon, :string

      timestamps()
    end

    alter table(:accounts__rewards) do
      add :type_id, references(:accounts__reward_types, on_delete: :delete_all), null: false
    end

    create index(:accounts__rewards, [:account_id])
    create index(:accounts__rewards, [:type_id])
  end
end
