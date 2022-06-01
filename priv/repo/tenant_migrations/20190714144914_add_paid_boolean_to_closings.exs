defmodule AppCount.Repo.Migrations.AddPaidBooleanToClosings do
  use Ecto.Migration

  def change do
    alter table(:leases__closings) do
      add :paid, :boolean, default: false, null: false
    end
  end
end
