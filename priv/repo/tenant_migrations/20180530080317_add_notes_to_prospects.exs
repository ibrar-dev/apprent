defmodule AppCount.Repo.Migrations.AddNotesToProspects do
  use Ecto.Migration

  def change do
    alter table(:prospects__prospects) do
      add :notes, :text
    end
  end
end
