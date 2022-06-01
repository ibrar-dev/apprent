defmodule AppCount.Repo.Migrations.ChangeSSNToText do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__persons) do
      modify :ssn, :text
    end
  end
end
