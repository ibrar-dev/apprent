defmodule AppCount.Jobs.Utils.Migrations do
  alias AppCount.Repo
  alias AppCount.Jobs.Migration
  import Ecto.Query

  def list_migrations() do
    from(j in Migration, select: map(j, [:id, :module, :function, :arguments]))
    |> Repo.all()
  end

  def create_migration(params) do
    %Migration{}
    |> Migration.changeset(params)
    |> Repo.insert()
  end

  def update_migration(id, params) do
    Repo.get(Migration, id)
    |> Migration.changeset(params)
    |> Repo.update()
  end

  def delete_migration(id) do
    Repo.get(Migration, id)
    |> Repo.delete()
  end
end
