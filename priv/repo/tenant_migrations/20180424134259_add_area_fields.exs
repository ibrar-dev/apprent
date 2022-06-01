defmodule AppCount.Repo.Migrations.AddAreaFields do
  use Ecto.Migration

  def change do
    alter table(:properties__units) do
      add :area, :integer, null: false, default: 0
    end

    alter table(:properties__properties) do
      add :area_rate, :decimal, null: false, default: 0
    end
  end
end
