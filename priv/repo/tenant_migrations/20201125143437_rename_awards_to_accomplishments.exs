defmodule AppCount.Repo.Migrations.RenameAwardsToAccomplishments do
  use Ecto.Migration

  def change do
    rename table(:rewards__awards), to: table(:rewards__accomplishments)
   end
end
