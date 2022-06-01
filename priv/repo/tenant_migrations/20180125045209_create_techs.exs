defmodule AppCount.Repo.Migrations.CreateTechs do
  use Ecto.Migration

  def change do
    create table(:maintenance__techs) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :phone_number, :string, null: false

      timestamps()
    end

  end
end
