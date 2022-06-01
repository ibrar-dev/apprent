defmodule AppCount.Repo.Migrations.ChangeChargesColumnName do
  use Ecto.Migration

  def change do
    alter table(:properties__charges) do
      add :name, :string, default: "Charge", null: false
    end
  end
end
