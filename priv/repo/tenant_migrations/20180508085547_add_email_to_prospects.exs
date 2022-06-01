defmodule AppCount.Repo.Migrations.AddEmailToProspects do
  use Ecto.Migration

  def change do
    alter table(:prospects__prospects) do
      add :email, :string
    end
  end
end
