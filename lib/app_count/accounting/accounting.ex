defmodule AppCount.Accounting do
  alias AppCount.Accounting.Utils.Accounts
  alias AppCount.Accounting.Utils.BankAccounts
  alias AppCount.Accounting.Utils.Categories
  alias AppCount.Accounting.Utils.Checks
  alias AppCount.Accounting.Utils.Closings
  alias AppCount.Accounting.Utils.Invoices
  alias AppCount.Accounting.Utils.JournalPages
  alias AppCount.Accounting.Utils.Payees
  alias AppCount.Accounting.Utils.Reconciliations
  alias AppCount.Accounting.Utils.Registers
  alias AppCount.Accounting.Utils.ReportTemplates
  alias AppCount.Accounting.PaymentAnalyticsBoundary

  def list_accounts(params), do: Accounts.list_accounts(params)
  def create_account(params), do: Accounts.create_account(params)
  def update_account(id, params), do: Accounts.update_account(id, params)
  def delete_account(admin, id), do: Accounts.delete_account(admin, id)

  def list_invoices(admin), do: Invoices.list_invoices(admin)
  def list_invoices(admin, params), do: Invoices.list_invoices(admin, params)
  def list_invoicings(admin), do: Invoices.list_invoicings(admin)
  def list_invoicings(admin, params), do: Invoices.list_invoicings(admin, params)
  def create_invoice(params), do: Invoices.create_invoice(params)
  def update_invoice(id, params), do: Invoices.update_invoice(id, params)
  def delete_invoice(id), do: Invoices.delete_invoice(id)
  def get_invoice(id), do: Invoices.get_invoice(id)
  def create_invoice_payment(params), do: Invoices.create_invoice_payment(params)
  def create_invoice_payments(params), do: Invoices.create_invoice_payments(params)

  def create_batch_payments(params, render_fn),
    do: Invoices.create_batch_payments(params, render_fn)

  def delete_invoice_payment(id), do: Invoices.delete_invoice_payment(id)

  def list_payees(), do: Payees.list_payees()
  def list_payees(:meta), do: Payees.list_payees(:meta)
  def create_payee(params), do: Payees.create_payee(params)
  def update_payee(id, params), do: Payees.update_payee(id, params)
  def delete_payee(id), do: Payees.delete_payee(id)
  def get_payee(id), do: Payees.get_payee(id)

  def list_bank_accounts(), do: BankAccounts.list_bank_accounts()
  def list_bank_accounts(property_id), do: BankAccounts.list_bank_accounts(property_id)
  def create_bank_account(params), do: BankAccounts.create_bank_account(params)
  def update_bank_account(id, params), do: BankAccounts.update_bank_account(id, params)
  def delete_bank_account(admin, id), do: BankAccounts.delete_bank_account(admin, id)
  def get_bank_account(id), do: BankAccounts.get_bank_account(id)

  def list_checks(), do: Checks.list_checks()

  def create_new_check(params, render_check_template_fn)
      when is_function(render_check_template_fn) do
    Checks.create_new_check(params, render_check_template_fn)
  end

  def create_check(params), do: Checks.create_check(params)

  def generate_check(params, render_fn), do: Checks.generate_check(params, render_fn)

  def find_pdfs(ids), do: Checks.find_pdfs(ids)

  def check_if_document_exists(ids, initial, render_check_template_fn),
    do: Checks.check_if_document_exists(ids, initial, render_check_template_fn)

  def show_check(id, render_fn), do: Checks.show_check(id, render_fn)

  def save_to_aws(binary, number, id), do: Checks.save_to_aws(binary, number, id)
  def update_check(id, params), do: Checks.update_check(id, params)
  def delete_check(admin, id, cascade), do: Checks.delete_check(admin, id, cascade)
  def get_check(id), do: Checks.get_check(id)

  def list_report_templates(), do: ReportTemplates.list_report_templates()
  def create_report_template(params), do: ReportTemplates.create_report_template(params)
  def update_report_template(id, params), do: ReportTemplates.update_report_template(id, params)
  def delete_report_template(id), do: ReportTemplates.delete_report_template(id)
  def balance_template(), do: ReportTemplates.balance_template()
  def income_template(), do: ReportTemplates.income_template()
  def get_template(name), do: ReportTemplates.get_template(name)
  def update_templates(), do: ReportTemplates.update_templates()

  def get_journal(id), do: JournalPages.get_journal(id)
  def list_journal_pages(), do: JournalPages.list_journal_pages()
  def create_journal_page(params), do: JournalPages.create_journal_page(params)
  def update_journal_page(id, params), do: JournalPages.update_journal_page(id, params)
  def delete_journal_page(id), do: JournalPages.delete_journal_page(id)

  def create_register(params), do: Registers.create_register(params)
  def update_register(id, params), do: Registers.update_register(id, params)
  def delete_register(id), do: Registers.delete_register(id)

  ## RECONCILE
  def list_unreconciled_transactions(filters),
    do: Reconciliations.list_unreconciled_transactions(filters)

  def create_reconciliation(params), do: Reconciliations.create_reconciliation(params)
  def list_postings(bank_id), do: Reconciliations.list_postings(bank_id)
  def create_posting(params), do: Reconciliations.create_posting(params)

  def get_posting(id, filters) do
    params =
      Reconciliations.get_posting(id)
      |> Map.merge(filters)

    Map.merge(%{transactions: list_unreconciled_transactions(params)}, params)
  end

  def update_posting(id, params), do: Reconciliations.update_posting(id, params)
  def post_reconciliation(id), do: Reconciliations.post_reconciliation(id)
  def delete_posting(id), do: Reconciliations.delete_posting(id)
  def undo_posting(id), do: Reconciliations.undo_posting(id)

  def list_closings(admin), do: Closings.list_closings(admin)
  def create_closing(admin, params), do: Closings.create_closing(admin, params)
  def update_closing(admin, id, params), do: Closings.update_closing(admin, id, params)
  def delete_closing(admin, id), do: Closings.delete_closing(admin, id)

  def get_post_month(property_id, inserted_at, starting_date, type),
    do: Closings.get_post_date(property_id, inserted_at, starting_date, type)

  def create_category(params), do: Categories.create_category(params)
  def update_category(id, params), do: Categories.update_category(id, params)
  def delete_category(id), do: Categories.delete_category(id)
  def account_tree(opts \\ []), do: Categories.account_tree(opts)
  def add_in_totals(list), do: Categories.add_in_totals(list)
  def category_max(cat), do: Categories.category_max(cat)
  def category_num_from_max(num), do: Categories.category_num_from_max(num)
  def get_depth(num), do: Categories.get_depth(num)
  def get_account_ids(min, max), do: Categories.get_account_ids(min, max)

  ## Payment Analytics
  def info_boxes_payment_analytics(property_ids, schema),
    do: PaymentAnalyticsBoundary.info_boxes_payment_analytics(property_ids, schema)

  def charts_payment_analytics(property_ids, dates, schema),
    do: PaymentAnalyticsBoundary.charts_payment_analytics(property_ids, dates, schema)
end
