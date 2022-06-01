defmodule AppCount.Repo.Migrations.ChangeNoAccessToArray do
  use Ecto.Migration

  def change do
    alter table(:maintenance__orders) do
      remove :no_access
      add :no_access, {:array, :map}, default: []
    end
  end
end
