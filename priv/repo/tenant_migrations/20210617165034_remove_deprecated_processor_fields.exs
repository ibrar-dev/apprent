defmodule AppCount.Repo.Migrations.RemoveDeprecatedProcessorFields do
  use Ecto.Migration

  def change do
    alter table("properties__processors") do
      remove :deprecated_keys
      remove :deprecated_password
    end
  end
end
