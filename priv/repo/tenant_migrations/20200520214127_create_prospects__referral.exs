defmodule AppCount.Repo.Migrations.CreateProspectsReferral do
  use Ecto.Migration

  def change do
    create table(:prospects__referral) do
      add :referrer, :string, null: false
      add :ip_address, :string, null: false

      timestamps()
    end
  end
end
