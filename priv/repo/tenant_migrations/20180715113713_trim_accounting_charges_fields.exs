defmodule AppCount.Repo.Migrations.TrimAccountingChargesFields do
  use Ecto.Migration

  def change do
#    type_id = AppCount.Repo.get_by(AppCount.Accounting.ChargeType, name: "Rent").id
#    AppCount.Repo.update_all(AppCount.Properties.Charge, set: [type_id: type_id])
    alter table(:properties__charges) do
      remove :description
      remove :name
      modify :type_id, :integer, null: false
    end

    alter table(:accounting__charges) do
      remove :description
      remove :account_id
      add :type_id, references(:accounting__charge_types, on_delete: :delete_all), null: false
    end

    create index(:accounting__charges, [:type_id])
  end
end
