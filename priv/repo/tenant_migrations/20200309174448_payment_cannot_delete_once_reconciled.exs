defmodule AppCount.Repo.Migrations.PaymentCannotDeleteOnceReconciled do
  use Ecto.Migration

  def change do
    execute(
      "CREATE RULE accounting__payments_delete AS ON DELETE TO #{prefix()}.accounting__payments WHERE OLD.reconciliation_id IS NOT NULL DO INSTEAD NOTHING",
      "DROP RULE accounting__payments_delete on #{prefix()}.accounting__payments"
    )

    execute(
      "CREATE RULE accounting__invoice_payments_delete AS ON DELETE TO #{prefix()}.accounting__invoice_payments WHERE OLD.reconciliation_id IS NOT NULL DO INSTEAD NOTHING",
      "DROP RULE accounting__invoice_payments_delete on #{prefix()}.accounting__invoice_payments"
    )

    execute(
      "CREATE RULE accounting__reconciliation_postings_undo AS ON DELETE TO #{prefix()}.accounting__reconciliation_postings WHERE OLD.is_posted DO INSTEAD NOTHING",
      "DROP RULE accounting__reconciliation_postings_undo on #{prefix()}.accounting__reconciliation_postings"
    )
  end
end
