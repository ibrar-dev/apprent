defmodule AppCount.Repo.Migrations.AddStatusToPayments do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      add :status, :string, null: false, default: "cleared"
      add :image, :string
    end
  end
end
