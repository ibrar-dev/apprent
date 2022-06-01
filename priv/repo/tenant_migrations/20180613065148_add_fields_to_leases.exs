defmodule AppCount.Repo.Migrations.AddFieldsToLeases do
  use Ecto.Migration

  def change do
    alter table(:properties__leases) do
      add :notice_date, :date
      add :deposit_amount, :decimal, null: false, default: 0
    end

    alter table(:properties__properties) do
      remove :application_fee
      remove :admin_fee
      remove :area_rate
    end
  end
end
