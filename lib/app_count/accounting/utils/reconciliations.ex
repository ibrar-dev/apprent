defmodule AppCount.Accounting.Utils.Reconciliations do
  import Ecto.Query
  alias Ecto.Multi
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Data

  alias AppCount.Ledgers.Batch
  alias AppCount.Accounting.Check
  alias AppCount.Ledgers.Payment
  alias AppCount.Accounting.Reconciliation
  alias AppCount.Accounting.JournalEntry
  alias AppCount.Accounting.ReconciliationPosting
  alias AppCount.Accounting.BankAccount

  def list_unreconciled_transactions(filters) do
    filters =
      Enum.map(
        filters,
        fn {k, v} ->
          v =
            if k == "start_date" or k == "end_date" do
              Date.from_iso8601!(v)
            else
              v
            end

          {stringify_key(k), v}
        end
      )
      |> Enum.into(%{})

    start_date = Timex.beginning_of_day(Timex.to_datetime(filters["start_date"]))
    end_date = Timex.beginning_of_day(Timex.to_datetime(filters["end_date"]))

    conditions =
      dynamic(
        [t, rec, posting],
        (rec.reconciliation_posting_id == ^filters["posting_id"] or
           is_nil(rec.reconciliation_posting_id)) and
          (is_nil(posting.id) or not posting.is_posted) and
          (t.inserted_at >= ^start_date or not is_nil(posting.id)) and
          (t.inserted_at <= ^end_date or not is_nil(posting.id))
      )

    conditions =
      if filters["posted_only"] do
        dynamic([t, rec, posting], rec.reconciliation_posting_id == ^filters["posting_id"])
      else
        conditions
      end

    (list_unreconciled_batches(filters, conditions) ++
       list_payments_wo_batch(filters, conditions) ++
       list_unreconciled_checks(filters, conditions) ++
       list_unreconciled_nsf_payments(filters, conditions) ++
       list_unreconciled_journal_entries(filters, conditions))
    |> Enum.sort_by(fn d -> {d.date.year, d.date.month, d.date.day} end)
  end

  def list_unreconciled_checks(filters, conditions) do
    conditions =
      dynamic([t, rec, posting], t.bank_account_id == ^filters["bank_account_id"] and ^conditions)

    from(
      c in Check,
      left_join: rec in "accounting__reconciliations",
      on: rec.check_id == c.id,
      left_join: rec_posting in "accounting__reconciliation_postings",
      on: rec.reconciliation_posting_id == rec_posting.id,
      left_join: pa in assoc(c, :payments),
      left_join: p in assoc(c, :payee),
      select: map(c, [:id, :date, :number, :payee_id]),
      select_merge: %{
        reconciled: not is_nil(rec.id),
        amount: sum(pa.amount),
        payee: p.name,
        type: "check",
        ref: c.number,
        clear_date: rec.clear_date,
        reconciliation_id: rec.id,
        memo: rec.memo
      },
      where: ^conditions,
      group_by: [c.id, p.name, rec.id]
    )
    |> Repo.all()
  end

  def list_unreconciled_journal_entries(filters, conditions) do
    bank_account =
      from(
        b in BankAccount,
        where: b.id == ^filters["bank_account_id"],
        join: p in assoc(b, :properties),
        select: map(b, [:id, :name]),
        select_merge: %{
          properties: jsonize(p, [p.id])
        },
        group_by: [b.id]
      )
      |> Repo.one()

    properties = Enum.map(bank_account.properties, fn p -> p["id"] end)

    conditions =
      dynamic(
        [t, rec, posting, acc],
        t.property_id in ^properties and acc.name == "Operating Account" and ^conditions
      )

    from(
      jr in JournalEntry,
      left_join: rec in "accounting__reconciliations",
      on: rec.journal_id == jr.id,
      left_join: rec_posting in "accounting__reconciliation_postings",
      on: rec.reconciliation_posting_id == rec_posting.id,
      join: account in assoc(jr, :account),
      join: p in assoc(jr, :property),
      join: page in assoc(jr, :page),
      where: ^conditions,
      select: %{
        type:
          fragment("CASE WHEN ? THEN 'journal_income' ELSE 'journal_expense' END", jr.is_credit),
        date: page.date,
        reconciled: not is_nil(rec.id),
        description: page.name,
        amount: jr.amount,
        clear_date: rec.clear_date,
        reconciliation_id: rec.id,
        memo: rec.memo,
        id: jr.id
      }
    )
    |> Repo.all()
  end

  def list_unreconciled_nsf_payments(filters, conditions) do
    conditions =
      dynamic(
        [t, rec, posting, batch],
        t.status == "nsf" and batch.bank_account_id == ^filters["bank_account_id"] and ^conditions
      )

    from(
      p in Payment,
      left_join: rec in "accounting__reconciliations",
      on: rec.payment_id == p.id,
      left_join: rec_posting in "accounting__reconciliation_postings",
      on: rec.reconciliation_posting_id == rec_posting.id,
      join: b in assoc(p, :batch),
      left_join: pr in assoc(p, :property),
      distinct: p.id,
      select:
        map(
          p,
          [
            :id,
            :source,
            :description,
            :property_id,
            :tenant_id,
            :post_month,
            :payer
          ]
        ),
      select_merge: %{
        reconciled: not is_nil(rec.id),
        clear_date: rec.clear_date,
        reconciliation_id: rec.id,
        memo: rec.memo,
        type: "nsf_payment",
        date: p.inserted_at,
        amount: p.amount
      },
      where: ^conditions,
      order_by: [
        desc: p.inserted_at
      ],
      group_by: [rec.id, rec_posting.id, p.id]
    )
    |> Repo.all()
  end

  def list_unreconciled_batches(filters, conditions) do
    conditions =
      dynamic([t, rec, posting], t.bank_account_id == ^filters["bank_account_id"] and ^conditions)

    from(
      b in Batch,
      left_join: rec in "accounting__reconciliations",
      on: rec.batch_id == b.id,
      left_join: rec_posting in "accounting__reconciliation_postings",
      on: rec.reconciliation_posting_id == rec_posting.id,
      left_join: pa in assoc(b, :payments),
      left_join: t in assoc(pa, :tenant),
      select: map(b, [:id, :property_id]),
      select_merge: %{
        amount: sum(pa.amount),
        clear_date: rec.clear_date,
        memo: rec.memo,
        reconciled: not is_nil(rec.id),
        reconciliation_id: rec.id,
        date: b.inserted_at,
        type: "batch",
        ref: b.id,
        payments:
          jsonize(
            pa,
            [
              :id,
              :amount,
              :inserted_at,
              :description,
              :payer,
              :transaction_id
            ]
          )
      },
      group_by: [b.id, rec.id],
      where: ^conditions
    )
    |> Repo.all()
  end

  def list_payments_wo_batch(_filters, conditions) do
    conditions =
      dynamic(
        [t, rec, posting, batch],
        is_nil(batch.id) and ^conditions
      )

    from(
      p in Payment,
      left_join: rec in "accounting__reconciliations",
      on: rec.payment_id == p.id,
      left_join: rec_posting in "accounting__reconciliation_postings",
      on: rec.reconciliation_posting_id == rec_posting.id,
      left_join: b in assoc(p, :batch),
      left_join: pr in assoc(p, :property),
      distinct: p.id,
      select:
        map(
          p,
          [
            :id,
            :source,
            :description,
            :property_id,
            :tenant_id,
            :post_month,
            :payer
          ]
        ),
      select_merge: %{
        reconciled: not is_nil(rec.id),
        reconciliation_id: rec.id,
        type: "payment_wo_batch",
        date: p.inserted_at,
        amount: p.amount,
        memo: rec.memo,
        clear_date: rec.clear_date
      },
      where: ^conditions,
      order_by: [
        desc: p.inserted_at
      ],
      group_by: [rec.id, rec_posting.id, p.id]
    )
    |> Repo.all()
  end

  def create_reconciliation(params) do
    posting_id = params["posting_id"]

    Multi.new()
    |> add_transactions(params["transactions"], posting_id)
    |> Repo.transaction()
  end

  @reference %{
    "check" => "check_id",
    "batch" => "batch_id",
    "nsf_payment" => "payment_id",
    "payment_wo_batch" => "payment_id",
    "journal_expense" => "journal_id",
    "journal_income" => "journal_id"
  }

  defp add_transactions(multi, transactions, posting_id) do
    Enum.reduce(
      transactions,
      multi,
      fn
        %{"reconciled" => true} = params, multi ->
          transaction =
            case params["reconciliation_id"] do
              nil ->
                Reconciliation.changeset(
                  %Reconciliation{},
                  Map.merge(
                    params,
                    %{
                      "#{@reference[params["type"]]}" => params["id"],
                      "reconciliation_posting_id" => posting_id
                    }
                  )
                )

              id ->
                Reconciliation.changeset(Repo.get(Reconciliation, id), params)
            end

          Multi.insert_or_update(
            multi,
            "#{params["type"]}#{params["id"]}",
            transaction
          )

        %{"reconciled" => false} = params, multi ->
          type = @reference[params["type"]]

          Multi.delete(
            multi,
            "#{params["type"]}#{params["id"]}",
            Repo.get_by(Reconciliation, "#{type}": params["id"])
          )
      end
    )
  end

  def post_reconciliation(id) do
    id = String.to_integer(id)
    posting = Repo.get(ReconciliationPosting, id)

    invoice_payments =
      from(
        p in AppCount.Accounting.InvoicePayment,
        join: check in assoc(p, :check),
        join: rec in "accounting__reconciliations",
        on: rec.check_id == check.id,
        where: rec.reconciliation_posting_id == ^id
      )

    payments =
      from(
        p in AppCount.Ledgers.Payment,
        join: batch in assoc(p, :batch),
        join: rec in "accounting__reconciliations",
        on: rec.batch_id == batch.id or rec.payment_id == p.id,
        where: rec.reconciliation_posting_id == ^id
      )

    Multi.new()
    |> Multi.update(:update_posting, ReconciliationPosting.changeset(posting, %{is_posted: true}))
    |> Multi.update_all(
      :reconciliation_id_invoice_payments,
      invoice_payments,
      set: [
        reconciliation_id: id
      ]
    )
    |> Multi.update_all(
      :reconciliation_id_payments,
      payments,
      set: [
        reconciliation_id: id
      ]
    )
    |> Multi.run(:genearate_json, fn _, _ -> generate_json(id) end)
    |> Repo.transaction()
  end

  def generate_json(posting_id) do
    posting =
      from(
        p in ReconciliationPosting,
        join: bank in assoc(p, :bank_account),
        where: p.id == ^posting_id,
        select: %{
          start_date: p.start_date,
          end_date: p.end_date,
          bank_account: bank.name,
          bank_id: bank.id
        }
      )
      |> Repo.one()

    {:ok, iodata} =
      list_unreconciled_transactions(%{
        "posting_id" => posting_id,
        "posted_only" => true,
        "bank_account_id" => posting.bank_id
      })
      |> Jason.encode_to_iodata()

    binary = IO.iodata_to_binary(iodata)
    filename = "#{posting.bank_account} #{posting.start_date} #{posting.end_date}"
    uuid = Data.binary_to_upload(binary, filename, "application/json")

    Repo.get(ReconciliationPosting, posting_id)
    |> ReconciliationPosting.changeset(%{
      document: %{
        "uuid" => uuid
      }
    })
    |> Repo.update()
  end

  def undo_posting(id) do
    id = String.to_integer(id)
    posting = Repo.get(ReconciliationPosting, id)

    invoice_payments =
      from(
        p in AppCount.Accounting.InvoicePayment,
        where: p.reconciliation_id == ^id
      )

    payments =
      from(
        p in AppCount.Ledgers.Payment,
        where: p.reconciliation_id == ^id
      )

    Multi.new()
    |> Multi.update(
      :update_posting,
      ReconciliationPosting.changeset(posting, %{is_posted: false})
    )
    |> Multi.update_all(
      :reconciliation_id_invoice_payments,
      invoice_payments,
      set: [
        reconciliation_id: nil
      ]
    )
    |> Multi.update_all(
      :reconciliation_id_payments,
      payments,
      set: [
        reconciliation_id: nil
      ]
    )
    |> Repo.transaction()
  end

  def create_posting(params) do
    Repo.insert(ReconciliationPosting.changeset(%ReconciliationPosting{}, params))
  end

  def list_postings(bank_id) do
    from(
      p in ReconciliationPosting,
      left_join: u in assoc(p, :document_url),
      join: b in assoc(p, :bank_account),
      select:
        map(
          p,
          [
            :id,
            :start_date,
            :admin,
            :is_posted,
            :bank_account_id,
            :total_payments,
            :total_deposits,
            :start_date,
            :end_date
          ]
        ),
      select_merge: %{
        document_url: u.url,
        bank_name: b.name
      },
      where: p.bank_account_id == ^bank_id
    )
    |> Repo.all()
  end

  def get_posting(id) do
    from(
      p in ReconciliationPosting,
      select:
        map(p, [:bank_account_id, :end_date, :start_date, :total_deposits, :total_payments]),
      select_merge: %{
        posting_id: p.id
      },
      where: p.id == ^id
    )
    |> Repo.one()
  end

  def update_posting(id, params) do
    Repo.get(ReconciliationPosting, id)
    |> ReconciliationPosting.changeset(params)
    |> Repo.update()
  end

  def delete_posting(id) do
    id = String.to_integer(id)
    posting = Repo.get(ReconciliationPosting, id)

    recs =
      from(
        r in Reconciliation,
        where: r.reconciliation_posting_id == ^id
      )

    Multi.new()
    |> Multi.delete_all(
      :delete_reconciliations,
      recs
    )
    |> Multi.delete(:delete_posting, posting)
    |> Repo.transaction()
  end

  defp stringify_key(key) when is_atom(key) do
    Atom.to_string(key)
  end

  defp stringify_key(key) do
    key
  end
end
