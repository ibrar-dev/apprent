defmodule AppCount.Repo.Migrations.RenameProcessorColumnsForKeySwap do
  use Ecto.Migration

  def change do
    rename table("properties__processors"), :keys, to: :deprecated_keys
    rename table("properties__processors"),  :local_keys, to: :keys

    rename table("properties__processors"), :password, to: :deprecated_password
    rename table("properties__processors"), :local_password, to: :password
  end
end
