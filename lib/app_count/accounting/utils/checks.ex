defmodule AppCount.Accounting.Utils.Checks do
  alias AppCount.Repo
  alias AppCount.Data
  alias AppCount.Accounting.Check
  alias AppCount.Accounting.InvoicePayment
  alias AppCount.Accounting.Invoice
  alias AppCount.Accounting.Invoicing
  alias AppCount.Accounting.BankAccount
  import Ecto.Query
  import AppCount.EctoExtensions
  require Logger

  def list_checks() do
    inv_query =
      from(
        i in Invoicing,
        join: p in assoc(i, :property),
        join: a in assoc(i, :account),
        join: inv in assoc(i, :invoice),
        select: map(i, [:id, :amount, :invoice_id]),
        select_merge: %{
          property: p.name,
          account: a.name,
          invoice_date: type(inv.inserted_at, :date),
          invoice_number: inv.number
        }
      )

    from(
      c in Check,
      left_join: pa in assoc(c, :payments),
      left_join: ch in assoc(c, :charge),
      left_join: t in assoc(c, :tenant),
      left_join: app in assoc(c, :applicant),
      left_join: i in subquery(inv_query),
      on: i.id == pa.invoicing_id,
      left_join: inv in Invoice,
      on: inv.id == i.invoice_id,
      left_join: p in assoc(c, :payee),
      left_join: u in assoc(c, :document_url),
      join: a in assoc(c, :bank_account),
      select: map(c, [:id, :date, :number, :cleared, :printed, :payee_id]),
      select_merge: %{
        document_url: u.url,
        amount: c.amount,
        bank_account:
          map(a, [:id, :name, :bank_name, :account_number, :routing_number, :address]),
        payee:
          coalesce(p.name, fragment("? || ' ' || ?", t.first_name, t.last_name))
          |> coalesce(app.full_name),
        notes: array(inv.notes),
        invoicings:
          jsonize(i, [:id, :amount, :property, :account, :invoice_date, :invoice_number])
      },
      group_by: [c.id, a.id, p.id, ch.id, t.id, u.url, app.id]
    )
    |> Repo.all()
  end

  def check_if_document_exists(ids, initial, render_check_template_fn)
      when is_function(render_check_template_fn) do
    docs =
      from(
        c in Check,
        join: u in assoc(c, :document),
        select: %{
          id: u.id,
          data: u
        },
        where: c.id in ^ids and u.is_loading == false
      )
      |> Repo.all()

    cond do
      length(ids) == length(docs) ->
        find_pdfs(ids)

      initial == true ->
        create_document(ids, render_check_template_fn)

      initial == false ->
        :timer.sleep(1000)
        check_if_document_exists(ids, true, render_check_template_fn)
    end
  end

  def create_document(ids, render_check_template_fn) when is_function(render_check_template_fn) do
    from(
      c in Check,
      left_join: ip in assoc(c, :payments),
      select: %{
        id: c.id,
        invoice_payment_ids: array(ip.id)
      },
      where: c.id in ^ids and is_nil(c.document_id),
      group_by: c.id
    )
    |> Repo.all()
    |> Enum.each(fn check ->
      get_check_params(check.id, check.invoice_payment_ids)
      |> generate_check(render_check_template_fn)
    end)

    check_if_document_exists(ids, false, render_check_template_fn)
  end

  def find_pdfs(ids) do
    from(
      c in Check,
      left_join: u in assoc(c, :document_url),
      select: u.url,
      where: c.id in ^ids
    )
    |> Data.concatenate_pdfs()
    |> convert_to_base64()
  end

  def generate_check(params, render_check_template_fn)
      when is_function(render_check_template_fn) do
    binary = render_check_template_fn.(params)

    case binary do
      {:ok, b} ->
        save_to_aws(b, params.number, params.id)
        binary

      {:error, error} ->
        error
    end
  end

  defp convert_to_base64({:error, e}), do: Logger.error(e)

  defp convert_to_base64(binary) do
    binary
    |> :erlang.term_to_binary()
    |> Base.encode64()
  end

  def create_new_check(params, render_check_template_fn)
      when is_function(render_check_template_fn) do
    create_check(params)
    |> case do
      {:ok, check} ->
        new_check =
          get_check_params(check.id)
          |> generate_check(render_check_template_fn)
          |> convert_to_base64

        {:ok, %{check_pdf: new_check, id: check.id}}

      e ->
        e
    end
  end

  def save_to_aws(binary, number, id) do
    filename = "Check No.#{number}.pdf"
    uuid = Data.binary_to_upload(binary, filename, "application/pdf")

    Repo.get(Check, id)
    |> Check.changeset(%{
      document: %{
        "uuid" => uuid
      }
    })
    |> Repo.update()
  end

  def create_check(params) do
    max_number =
      from(
        c in Check,
        join: b in assoc(c, :bank_account),
        where: b.id == ^params["bank_account_id"],
        select: max(c.number)
      )
      |> Repo.one()

    new_number =
      if(params["number"] && params["number"] > max_number) do
        params["number"]
      else
        (max_number || 0) + 1
      end

    %Check{}
    |> Check.changeset(Map.put(params, "number", new_number))
    |> Repo.insert()
    |> attach_invoicings(params)
  end

  def show_check(id, render_check_template_fn) when is_function(render_check_template_fn) do
    check = Repo.get(Check, id)

    if(is_nil(check.document_id)) do
      get_check_params(check.id)
      |> generate_check(render_check_template_fn)
      |> convert_to_base64
    else
      find_pdfs([check.id])
    end
  end

  defp inv_query() do
    from(
      i in Invoicing,
      join: p in assoc(i, :property),
      join: a in assoc(i, :account),
      join: inv in assoc(i, :invoice),
      join: pa in assoc(i, :payments),
      select: map(i, [:id, :amount, :invoice_id]),
      select_merge: %{
        property: p.name,
        account: a.name,
        invoice_date: type(inv.inserted_at, :date),
        invoice_number: inv.number,
        amount: pa.amount
      },
      group_by: [i.id, pa.id, p.id, a.id, inv.id]
    )
  end

  def get_check_params(id, [_ | _] = invoice_payments) do
    inv_query =
      inv_query()
      |> where([_, _, _, _, pa], pa.id in ^invoice_payments)

    from(
      c in Check,
      left_join: ch in assoc(c, :charge),
      left_join: t in assoc(c, :tenant),
      join: i in assoc(c, :invoicings),
      left_join: ni in subquery(inv_query),
      on: i.id == ni.id,
      left_join: inv in assoc(i, :invoice),
      left_join: p in assoc(c, :payee),
      join: a in assoc(c, :bank_account),
      where: c.id == ^id,
      select: map(c, [:id, :date, :number, :cleared, :printed, :payee_id, :amount_lang]),
      select_merge: %{
        amount: sum(coalesce(ni.amount, 0)),
        bank_account:
          map(a, [:id, :name, :bank_name, :account_number, :routing_number, :address]),
        payee: coalesce(p.name, fragment("? || ' ' || ?", t.first_name, t.last_name)),
        notes: array(inv.notes),
        invoicings:
          jsonize(ni, [:id, :amount, :property, :account, :invoice_date, :invoice_number])
      },
      group_by: [c.id, a.id, p.id, ch.id, t.id]
    )
    |> Repo.one()
  end

  def get_check_params(id, _array), do: get_check_params(id)

  def get_check_params(id) do
    inv_query = inv_query()

    from(
      c in Check,
      left_join: ch in assoc(c, :charge),
      left_join: t in assoc(c, :tenant),
      left_join: app in assoc(c, :applicant),
      left_join: i in assoc(c, :invoicings),
      left_join: ni in subquery(inv_query),
      on: i.id == ni.id,
      left_join: inv in assoc(i, :invoice),
      left_join: p in assoc(c, :payee),
      join: a in assoc(c, :bank_account),
      where: c.id == ^id,
      select: map(c, [:id, :date, :number, :cleared, :printed, :payee_id, :amount_lang]),
      select_merge: %{
        amount: c.amount,
        bank_account:
          map(a, [:id, :name, :bank_name, :account_number, :routing_number, :address]),
        payee:
          coalesce(p.name, fragment("? || ' ' || ?", t.first_name, t.last_name))
          |> coalesce(app.full_name),
        notes: array(inv.notes),
        invoicings:
          jsonize(ni, [:id, :amount, :property, :account, :invoice_date, :invoice_number])
      },
      group_by: [c.id, a.id, p.id, ch.id, t.id, app.id]
    )
    |> Repo.one()
  end

  def update_check(id, params) do
    Repo.get(Check, id)
    |> Check.changeset(params)
    |> Repo.update()
    |> attach_invoicings(params)
  end

  def attach_invoicings({:ok, check}, %{"invoicings" => invoicings} = params) do
    account_id = Repo.get(BankAccount, params["bank_account_id"])
    invoicing_ids = Enum.map(invoicings, & &1["invoicing_id"])

    from(
      p in InvoicePayment,
      where: p.check_id == ^check.id and p.invoicing_id not in ^invoicing_ids
    )
    |> Repo.delete_all()

    invoice_payment =
      Enum.map(
        invoicings,
        fn invoicing_params ->
          %InvoicePayment{}
          |> InvoicePayment.changeset(
            Map.put(invoicing_params, "check_id", check.id)
            |> Map.put("account_id", account_id.account_id)
          )
          |> Repo.insert(
            on_conflict: {:replace_all_except, [:id]},
            conflict_target: [:invoicing_id, :check_id]
          )
          |> case do
            {:ok, ip} -> ip.id
            {:error, e} -> e
          end
        end
      )
      |> Enum.filter(fn x -> is_integer(x) end)

    {
      :ok,
      check
      |> Map.from_struct()
      |> Map.put(:invoice_payment_ids, invoice_payment)
    }
  end

  def attach_invoicings(e, _), do: e

  def delete_check(admin, id, "true") do
    from(p in InvoicePayment, where: p.check_id == ^id)
    |> Repo.delete_all()

    delete_check(admin, id, "false")
  end

  def delete_check(admin, id, "false") do
    case Repo.get(Check, id) do
      nil -> nil
      check -> AppCount.Admins.Utils.Actions.admin_delete(check, admin)
    end
  end

  def get_check(id) do
    Repo.get(Check, id)
  end
end
