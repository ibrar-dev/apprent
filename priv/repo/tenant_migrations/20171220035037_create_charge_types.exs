defmodule AppCount.Repo.Migrations.CreateChargeTypes do
  use Ecto.Migration

  def change do
    create table(:accounting__charge_types) do
      add :code, :string, null: false
      add :description, :text, null: false

      timestamps()
    end

  end
end
