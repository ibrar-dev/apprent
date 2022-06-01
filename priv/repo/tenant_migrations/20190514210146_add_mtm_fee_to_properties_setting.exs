defmodule AppCount.Repo.Migrations.AddMTMFeeToPropertiesSetting do
  use Ecto.Migration

  def change do
    alter table(:properties__settings) do
      add :mtm_fee, :integer, null: false, default: 250
    end
  end
end
