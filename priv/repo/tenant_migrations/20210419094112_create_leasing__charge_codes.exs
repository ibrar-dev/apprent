defmodule AppCount.Repo.Migrations.CreateLeasingChargeCodes do
  use Ecto.Migration

  def change do
    create table(:leasing__charge_codes) do
      add :code, :string, null: false
      add :name, :string, null: false
      add :is_default, :boolean, null: false, default: false
      add :account_id, references(:accounting__accounts, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:leasing__charge_codes, [:account_id])
    create unique_index(:leasing__charge_codes, [:code])
    create unique_index(:leasing__charge_codes, [:account_id],
             where: "is_default = 't'", name: :leasing__charge_codes_account_id_default)

  end
end
