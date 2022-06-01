defmodule AppCount.Repo.Migrations.DropModuleFieldFromJobs do
  use Ecto.Migration

  def change do
    alter table(:jobs__jobs) do
      remove :module
    end
  end
end
