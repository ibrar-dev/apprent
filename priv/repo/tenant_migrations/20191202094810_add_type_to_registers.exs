defmodule AppCount.Repo.Migrations.AddTypeToRegisters do
  use Ecto.Migration

  def change do
    alter table(:accounting__registers) do
      add :type, :string, null: false, default: "cash"
    end

    drop unique_index(:accounting__registers, [:property_id])
    drop unique_index(:accounting__registers, [:property_id, :cash_account_id])
    create unique_index(:accounting__registers, [:property_id, :account_id])
    create unique_index(:accounting__registers, [:property_id, :type], where: "is_default = 't'")
  end
end
