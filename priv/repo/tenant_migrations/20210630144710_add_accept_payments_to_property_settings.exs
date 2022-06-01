defmodule AppCount.Repo.Migrations.AddAcceptPaymentsToPropertySettings do
  use Ecto.Migration

  def change do
    alter table("properties__settings") do
      add :payments_accepted, :boolean, null: false, default: true
    end
  end
end
