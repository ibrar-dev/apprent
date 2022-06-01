defmodule AppCount.Repo.Migrations.AddTicketToOrders do
  use Ecto.Migration

  def change do
    alter table(:maintenance__orders) do
      add :ticket, :string, null: false, default: "UNKNOWN"
    end
  end
end
