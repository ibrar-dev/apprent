defmodule AppCount.Repo.Migrations.CreateAccountingChargeCodes do
  use Ecto.Migration

  def change do
    create table(:accounting__charge_codes) do
      add :code, :string, null: false
      add :name, :text
      add :is_default, :boolean, null: false, default: false
      add :account_id, references(:accounting__accounts, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:accounting__charge_codes, [:account_id])
    create unique_index(:accounting__charge_codes, [:code])
    create unique_index(:accounting__charge_codes, [:account_id],
             where: "is_default = 't'", name: :accounting__charge_codes_account_id_default)
  end
end
