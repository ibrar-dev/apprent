defmodule AppCount.Repo.Migrations.UniqueIndicesForAccounting do
  use Ecto.Migration

  def change do
    create unique_index(:accounting__accounts, [:name])
    rename table(:accounting__charge_types), :description, to: :name
    alter table(:accounting__charge_types) do
      modify :name, :string, null: false
    end
    alter table(:properties__charges) do
      remove :account_id
    end
    create unique_index(:accounting__charge_types, [:name])
  end
end
