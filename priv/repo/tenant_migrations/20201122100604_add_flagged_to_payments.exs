defmodule AppCount.Repo.Migrations.AddFlaggedToPayments do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      add :post_error, :text
    end
  end
end
