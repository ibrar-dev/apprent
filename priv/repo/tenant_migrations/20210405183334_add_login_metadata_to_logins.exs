defmodule AppCount.Repo.Migrations.AddLoginMetadataToLogins do
  use Ecto.Migration

  def change do
    alter table("accounts__logins") do
      add :login_metadata, :map, default: %{}
    end
  end
end
