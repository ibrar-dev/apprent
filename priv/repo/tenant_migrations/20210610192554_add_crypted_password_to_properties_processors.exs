defmodule AppCount.Repo.Migrations.AddCryptedPasswordToPropertiesProcessors do
  use Ecto.Migration

  def change do
    alter table("properties__processors") do
      add :local_password, :text, default: ""
    end
  end
end
