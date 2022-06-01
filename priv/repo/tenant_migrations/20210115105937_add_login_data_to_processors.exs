defmodule AppCount.Repo.Migrations.AddLoginDataToProcessors do
  use Ecto.Migration

  def change do
    alter table(:properties__processors) do
      add :login, :string
      add :password, :text
    end
  end
end
