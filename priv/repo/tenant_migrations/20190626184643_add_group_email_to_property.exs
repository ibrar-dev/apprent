defmodule AppCount.Repo.Migrations.AddGroupEmailToProperty do
  use Ecto.Migration

  def change do
    alter table(:properties__properties) do
      add :group_email, :string, null: true
    end
  end
end
