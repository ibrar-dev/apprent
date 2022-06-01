defmodule AppCount.Repo.Migrations.AddPostMonthFields do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      add :post_month, :date
    end

    alter table(:accounting__charges) do
      add :post_month, :date
    end

    alter table(:accounting__journal_pages) do
      add :post_month, :date
    end

    alter table(:accounting__invoice_payments) do
      add :post_month, :date
    end
  end
end
