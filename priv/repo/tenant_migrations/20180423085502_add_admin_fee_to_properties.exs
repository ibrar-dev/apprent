defmodule AppCount.Repo.Migrations.AddAdminFeeToProperties do
  use Ecto.Migration

  def change do
    alter table(:properties__properties) do
      add :admin_fee, :decimal, default: 0, null: false
    end
  end
end
