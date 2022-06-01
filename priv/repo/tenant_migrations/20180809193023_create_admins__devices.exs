defmodule AppCount.Repo.Migrations.CreateAdminsDevices do
  use Ecto.Migration

  def change do
    create table(:admins__devices) do
      add :name, :string, null: false
      add :public_cert, :text, null: false
      add :private_cert, :text, null: false
      add :nonce, :string, null: false
      add :identifier, :uuid, default: fragment("uuid_generate_v4()"), null: false

      timestamps()
    end

    create unique_index(:admins__devices, [:name])
  end
end
