defmodule AppCount.Accounting.Utils.Invoices do
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Data
  alias AppCount.Accounting.Invoice
  alias AppCount.Accounting.Invoicing
  alias AppCount.Accounting.BankAccount
  alias AppCount.Accounting.Check
  alias AppCount.Accounting.InvoicePayment
  alias AppCount.Accounting.Entity
  import Ecto.Query
  alias Ecto.Multi
  import AppCount.EctoExtensions
  require Logger
  alias AppCount.Core.ClientSchema

  def list_invoices(admin) do
    invoice_query(admin)
    |> Repo.all()
  end

  def list_invoices(admin, params) do
    number_filter =
      cond do
        number = params["number"] ->
          dynamic([i, inv], like(i.number, ^"#{number}%"))

        true ->
          true
      end

    account_filter =
      cond do
        account_id = params["account_id"] ->
          dynamic([i, inv], ^account_id == inv.ba_id)

        true ->
          true
      end

    property_filter =
      cond do
        property_id = params["property_id"] ->
          dynamic([i, inv], ^property_id == inv.property_id)

        true ->
          true
      end

    payee_filter =
      cond do
        payee_id = params["payee_id"] ->
          dynamic([i, b, c, payee], payee.id == ^payee_id)

        true ->
          true
      end

    date_filter =
      cond do
        params["due_date_start"] && params["due_date_end"] ->
          dynamic(
            [i],
            i.due_date >= ^params["due_date_start"] and i.due_date <= ^params["due_date_end"]
          )

        date = params["due_date_start"] ->
          dynamic([i], i.due_date >= ^date)

        date = params["due_date_end"] ->
          dynamic([i], i.due_date <= ^date)

        true ->
          true
      end

    invoice_query(admin)
    |> where(^payee_filter)
    |> where(^property_filter)
    |> where(^account_filter)
    |> where(^date_filter)
    |> where(^number_filter)
    |> Repo.all()
  end

  def invoice_query(admin) do
    check_query =
      from(
        p in InvoicePayment,
        left_join: ch in assoc(p, :check),
        select: map(p, [:id, :invoicing_id, :amount, :account_id]),
        select_merge: %{
          check_number: ch.number,
          date: p.inserted_at
        },
        group_by: [p.id, ch.id]
      )

    ba_query =
      from(
        ba in BankAccount,
        left_join: ch in assoc(ba, :checks),
        select: map(ba, [:id, :name, :bank_name, :address, :account_number, :routing_number]),
        select_merge: %{
          max_number: max(ch.number)
        },
        group_by: ba.id
      )

    # DO NOT ADD BACK IN THE BANK ACCOUNT TO GROUP_BY. THIS CAUSES ALL THE INVOICES TO BE DUPLICATED IF A PROPERTY HAS MORE THAN ONE BANK ACCOUNT
    query =
      from(
        i in Invoicing,
        join: p in assoc(i, :property),
        left_join: c in subquery(check_query),
        on: c.invoicing_id == i.id,
        left_join: e in Entity,
        on: e.property_id == p.id,
        left_join: ba in subquery(ba_query),
        on: ba.id == e.bank_account_id,
        select: map(i, [:id, :invoice_id, :account_id, :property_id, :amount, :notes]),
        select_merge: %{
          bank_accounts: jsonize(ba, [:id, :name, :bank_name]),
          property_name: p.name,
          payments: jsonize(c, [:id, :amount, :check_number, :date, :account_id])
        },
        group_by: [i.id, p.id]
      )

    from(
      i in Invoice,
      left_join: inv in subquery(query),
      on: inv.invoice_id == i.id,
      left_join: doc in assoc(i, :document_url),
      left_join: payee in assoc(i, :payee),
      select:
        map(
          i,
          [
            :id,
            :post_month,
            :payee_id,
            :payable_account_id,
            :number,
            :due_date,
            :notes,
            :date,
            :amount
          ]
        ),
      select_merge: %{
        document_url: doc.url,
        payee: map(payee, [:id, :name, :consolidate_checks]),
        invoicings:
          jsonize(
            inv,
            [
              :id,
              :account_id,
              :property_name,
              :property_id,
              :amount,
              :notes,
              :payments,
              :bank_accounts
            ]
          ),
        received: type(i.inserted_at, :date)
      },
      where: inv.property_id in ^Admins.property_ids_for(ClientSchema.new("dasmen", admin)),
      group_by: [i.id, doc.url, payee.id],
      order_by: [
        desc: i.date
      ]
    )
  end

  def list_invoicings(admin) do
    invoicing_query(admin)
    |> Repo.all()
  end

  def list_invoicings(admin, params) do
    account_filter =
      cond do
        account_id = params["account_id"] ->
          dynamic([i, b, c, ba], ^account_id == ba.id)

        true ->
          true
      end

    property_filter =
      cond do
        property_id = params["property_id"] ->
          dynamic([i, p], ^property_id == p.id)

        true ->
          true
      end

    payee_filter =
      cond do
        payee_id = params["payee_id"] ->
          dynamic([i, b, c, d, inv, payee], payee.id == ^payee_id)

        true ->
          true
      end

    date_filter =
      cond do
        params["due_date_start"] && params["due_date_end"] ->
          dynamic(
            [i, b, c, d, inv],
            inv.due_date >= ^params["due_date_start"] and inv.due_date <= ^params["due_date_end"]
          )

        date = params["due_date_start"] ->
          dynamic([i, b, c, d, inv], inv.due_date >= ^date)

        date = params["due_date_end"] ->
          dynamic([i, b, c, d, inv], inv.due_date <= ^date)

        true ->
          true
      end

    invoicing_query(admin)
    |> where(^payee_filter)
    |> where(^account_filter)
    |> where(^property_filter)
    |> where(^date_filter)
    |> Repo.all()
  end

  def invoicing_query(admin) do
    check_query =
      from(
        c in Check,
        join: p in assoc(c, :payments),
        select: map(c, [:id, :number]),
        select_merge: %{
          amount: sum(p.amount),
          invoicing_id: p.invoicing_id
        },
        group_by: [c.id, p.invoicing_id]
      )

    ba_query =
      from(
        ba in BankAccount,
        left_join: ch in assoc(ba, :checks),
        select: map(ba, [:id, :name, :bank_name, :address, :account_number, :routing_number]),
        select_merge: %{
          max_number: max(ch.number)
        },
        group_by: ba.id
      )

    from(
      i in Invoicing,
      left_join: pr in assoc(i, :property),
      left_join: e in Entity,
      on: e.property_id == pr.id,
      left_join: ba in subquery(ba_query),
      on: ba.id == e.bank_account_id,
      join: inv in assoc(i, :invoice),
      join: p in assoc(inv, :payee),
      join: a in assoc(i, :account),
      left_join: ch in subquery(check_query),
      on: ch.invoicing_id == i.id,
      left_join: payment in assoc(i, :payments),
      select: map(i, [:id, :invoice_id, :property_id, :account_id, :amount]),
      select_merge: %{
        payments: jsonize(payment, [:id, :amount]),
        account_name: a.name,
        property_name: pr.name,
        invoice_number: inv.number,
        due_date: inv.due_date,
        payee: p.name,
        payee_id: p.id,
        checks: jsonize(ch, [:id, :number, :amount]),
        bank_accounts:
          jsonize(
            ba,
            [
              :id,
              :name,
              :bank_name,
              :address,
              :account_number,
              :routing_number,
              :max_number
            ]
          ),
        notes: inv.notes,
        invoice_date: type(inv.inserted_at, :date)
      },
      where: pr.id in ^Admins.property_ids_for(ClientSchema.new("dasmen", admin)),
      group_by: [i.id, pr.id, a.id, inv.id, p.id]
    )
  end

  def create_invoice(%{"invoicings" => _} = params) do
    Multi.new()
    |> Multi.insert(:invoice, Invoice.changeset(%Invoice{}, params))
    |> process_invoicings(params["invoicings"])
    |> Repo.transaction()
  end

  def create_invoice(params) do
    %Invoice{}
    |> Invoice.changeset(params)
    |> Repo.insert()
  end

  def process_invoicings(multi, nil), do: multi

  def process_invoicings(multi, invoicings) do
    Multi.run(
      multi,
      :invoicings,
      fn _, cs ->
        Enum.reduce_while(
          invoicings,
          {:ok, []},
          &add_invoicing(Map.merge(&1, %{"invoice_id" => cs.invoice.id}), &2)
        )
      end
    )
  end

  defp add_invoicing(params, {:ok, invoicings}) do
    %Invoicing{}
    |> Invoicing.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, invoicing} -> {:cont, {:ok, invoicings ++ [invoicing]}}
      {:error, e} -> {:halt, {:error, e}}
    end
  end

  def update_invoice(id, %{"invoicings" => invoicings} = params) do
    attach_to_properties(id, invoicings)
    update_invoice(id, Map.delete(params, "invoicings"))
  end

  def update_invoice(id, params) do
    Repo.get(Invoice, id)
    |> Invoice.changeset(params)
    |> Repo.update()
  end

  def delete_invoice(id) do
    Repo.get(Invoice, id)
    |> Repo.delete()
  end

  def attach_to_properties(invoice_id, invoicings) do
    Enum.each(
      invoicings,
      fn i ->
        Map.put(i, "invoice_id", invoice_id)
        |> update_invoicing
      end
    )
  end

  def attach_invoicings(invoice_id, invoicings) do
    Enum.each(
      invoicings,
      fn i ->
        Map.put(i, "invoice_id", invoice_id)
        |> create_invoicing
      end
    )
  end

  def update_invoicing(params) do
    Repo.get(Invoicing, params["id"])
    |> Invoicing.changeset(params)
    |> Repo.update()
  end

  def create_invoicing(params) do
    %Invoicing{}
    |> Invoicing.changeset(params)
    |> Repo.insert()
  end

  def get_invoice(id) do
    Repo.get(Invoice, id)
    |> Repo.preload(:document_url)
  end

  def create_invoice_payment(%{"check" => check_params} = params) do
    case AppCount.Accounting.create_check(check_params) do
      {:ok, %{id: id}} ->
        params
        |> Map.delete("check")
        |> Map.put("check_id", id)
        |> create_invoice_payment

      e ->
        e
    end
  end

  def create_invoice_payment(params) do
    new_params =
      cond do
        params[:post_month] -> params
        params["post_month"] -> params
        params[:amount] -> Map.put(params, :post_month, post_month(params.invoicing_id))
        params["amount"] -> Map.put(params, "post_month", post_month(params["invoicing_id"]))
      end

    %InvoicePayment{}
    |> InvoicePayment.changeset(new_params)
    |> Repo.insert()
  end

  def create_invoice_payments(%{"check" => check_params} = params) do
    case AppCount.Accounting.create_check(check_params) do
      {:ok, %{id: id}} ->
        params2 =
          params
          |> Map.delete("check")
          |> Map.put("check_id", id)

        invoice = Multi.new()

        _changeSets =
          Enum.map(
            params["invoice"]["invoicings"],
            fn x ->
              create_invoice_payment_multi(%{
                "amount" => x["amount"],
                "check_id" => params2["check_id"],
                "invoicing_id" => x["id"],
                "account_id" => x["account_id"]
              })
            end
          )
          |> Enum.map(fn x ->
            key = String.to_atom(Integer.to_string(x.changes.invoicing_id))
            Multi.insert(Multi.new(), key, x)
          end)
          |> Enum.reduce(invoice, &Multi.append/2)
          |> Repo.transaction()

      e ->
        e
    end
  end

  def create_batch_payments(%{"checks" => checks}, render_fn) do
    Enum.reduce_while(
      checks,
      [],
      fn check_params, acc ->
        with {:ok, check} <- AppCount.Accounting.create_check(check_params),
             {:ok, new_pdf} <- generate_check_pdf(check, render_fn) do
          {:cont, [new_pdf | acc]}
        else
          {:error, _} = e -> {:halt, e}
        end
      end
    )
    |> case do
      {:error, _} = e ->
        e

      pdfs ->
        pdfs
        |> Data.concatenate_pdfs()
        |> convert_to_base64()
    end
  end

  defp generate_check_pdf(check, render_fn) do
    AppCount.Accounting.Utils.Checks.get_check_params(check.id, check.invoice_payment_ids)
    |> AppCount.Accounting.generate_check(render_fn)
  end

  defp convert_to_base64({:error, e}), do: Logger.error(e)

  defp convert_to_base64(binary) do
    binary
    |> :erlang.term_to_binary()
    |> Base.encode64()
  end

  def create_invoice_payment_multi(params) do
    new_params =
      cond do
        params[:post_month] -> params
        params["post_month"] -> params
        params[:amount] -> Map.put(params, :post_month, post_month(params.invoicing_id))
        params["amount"] -> Map.put(params, "post_month", post_month(params["invoicing_id"]))
      end

    %InvoicePayment{}
    |> InvoicePayment.changeset(new_params)
  end

  def delete_invoice_payment(id) do
    Repo.get(InvoicePayment, id)
    |> Repo.delete()
  end

  defp post_month(invoicing_id) do
    now = AppCount.current_time()

    property_id =
      from(i in Invoicing, where: i.id == ^invoicing_id, select: i.property_id)
      |> Repo.one()

    AppCount.Accounting.get_post_month(property_id, now, now, "payables")
  end
end
