defmodule AppCount.Repo.Migrations.AddMemoToPayments do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      add :memo, :string
    end
  end
end
