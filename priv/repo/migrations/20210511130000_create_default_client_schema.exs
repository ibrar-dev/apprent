defmodule AppCount.Repo.Migrations.CreateDefaultClientSchema do
  use Ecto.Migration

  def up do
    unless Enum.member?(Triplex.all(), "dasmen") do
      Triplex.rename("public", "dasmen")
      execute("CREATE SCHEMA public")
    end
  end

  def down do
    unless Enum.member?(Triplex.all(), "dasmen") do
      execute("DROP SCHEMA IF EXISTS public CASCADE")
      execute("ALTER SCHEMA dasmen RENAME TO public")
    end
  end
end
