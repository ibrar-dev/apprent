defmodule AppCount.Repo.Migrations.ChangeNameToStatus do
  use Ecto.Migration

  def change do
    alter table(:maintenance__clocks) do
      remove :in
      add :status, :boolean, default: false, null: false
    end
  end
end
