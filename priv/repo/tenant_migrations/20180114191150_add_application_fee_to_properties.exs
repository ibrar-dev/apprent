defmodule AppCount.Repo.Migrations.AddApplicationFeeToProperties do
  use Ecto.Migration

  def change do
    alter table(:properties__properties) do
      add :application_fee, :decimal, default: 0, null: false
    end
  end
end
