defmodule AppCount.Repo.Migrations.AddPayerToPayments do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      add :payer, :string
    end
  end
end
