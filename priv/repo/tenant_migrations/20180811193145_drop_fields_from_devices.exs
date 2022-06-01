defmodule AppCount.Repo.Migrations.DropFieldsFromDevices do
  use Ecto.Migration

  def change do
    alter table(:admins__devices) do
      remove :nonce
      remove :identifier
    end
  end
end
