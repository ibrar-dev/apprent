defmodule AppCount.Repo.Migrations.ChangePersonSSNToText do
  use Ecto.Migration

  def change do
    alter table(:properties__persons) do
      modify :ssn, :text
    end
  end
end
