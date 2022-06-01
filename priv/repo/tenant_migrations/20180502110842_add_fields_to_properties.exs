defmodule AppCount.Repo.Migrations.AddFieldsToProperties do
  use Ecto.Migration

  def change do
    alter table(:properties__properties) do
      add :phone, :string
      add :hours, :string
    end
  end
end
