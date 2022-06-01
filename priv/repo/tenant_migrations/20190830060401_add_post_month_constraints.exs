defmodule AppCount.Repo.Migrations.AddPostMonthConstraints do
  use Ecto.Migration

  def change do
    create constraint(:accounting__payments, :valid_post_month, check: "EXTRACT(DAY FROM post_month) = 1")
    create constraint(:accounting__charges, :valid_post_month, check: "EXTRACT(DAY FROM post_month) = 1")
    create constraint(:accounting__journal_pages, :valid_post_month, check: "EXTRACT(DAY FROM post_month) = 1")
    create constraint(:accounting__invoice_payments, :valid_post_month, check: "EXTRACT(DAY FROM post_month) = 1")
    create constraint(:accounting__invoices, :valid_post_month, check: "EXTRACT(DAY FROM post_month) = 1")
  end
end
