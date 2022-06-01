defmodule AppCount.Repo.Migrations.MakePostPonthRequired do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      modify :post_month, :date, null: false
    end

    alter table(:accounting__charges) do
      modify :post_month, :date, null: false
    end

    alter table(:accounting__journal_pages) do
      modify :post_month, :date, null: false
    end

    alter table(:accounting__invoice_payments) do
      modify :post_month, :date, null: false
    end
  end
end
