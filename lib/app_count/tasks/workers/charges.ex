defmodule AppCount.Tasks.Workers.Charges do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Accounting
  alias AppCount.Properties.Charge
  alias AppCount.Leases.Lease
  alias AppCount.Ledgers
  alias AppCount.Ledgers.Utils.Charges
  use AppCount.Decimal
  use AppCount.Tasks.Worker, "Create lease charges"
  alias AppCount.Core.ClientSchema

  def recalculate() do
    Repo.all(Lease)
    |> Enum.each(fn lease ->
      from(c in Charge, join: l in assoc(c, :lease), where: c.lease_id == ^lease.id)
      |> set_next_bill(lease.start_date)
    end)

    ids = perform()

    from(c in Ledgers.Charge, where: c.id not in ^ids and c.status == "charge")
    |> Repo.delete_all()

    AppCount.Repo.reset_id(Ledgers.Charge)
  end

  def recalculate_tenant(tenant_id) do
    from(o in AppCount.Properties.Occupancy, where: o.tenant_id == ^tenant_id, select: o.lease_id)
    |> Repo.all()
    |> Enum.each(&recalculate/1)
  end

  def recalculate(lease_id) do
    lease = Repo.get(Lease, lease_id)

    from(c in Charge, join: l in assoc(c, :lease), where: c.lease_id == ^lease.id)
    |> set_next_bill(lease.start_date)

    ids = perform()

    from(
      c in Ledgers.Charge,
      where: c.lease_id == ^lease_id and c.id not in ^ids and c.status == "charge"
    )
    |> Repo.delete_all()
  end

  #
  #  def recalculate(property_id, start_date) do
  #    ts = parse_date(start_date)
  #
  #    from(
  #      c in Charge,
  #      join: l in assoc(c, :lease),
  #      join: u in assoc(l, :unit),
  #      where: u.property_id == ^property_id
  #    )
  #    |> set_next_bill(ts)
  #
  #    ids = perform(property_id, start_date)
  #
  #    from(
  #      c in Accounting.Charge,
  #      join: l in assoc(c, :lease),
  #      join: u in assoc(l, :unit),
  #      where: c.id not in ^ids and c.status == "charge" and u.property_id == ^property_id
  #    )
  #    |> Repo.delete_all()
  #  end

  def perform(property_id, _start_date) do
    date =
      AppCount.current_date()
      |> Timex.beginning_of_month()

    from(
      c in Charge,
      join: l in assoc(c, :lease),
      join: u in assoc(l, :unit),
      where: c.next_bill_date <= ^date or is_nil(c.next_bill_date),
      where: l.start_date <= ^date,
      where: u.property_id == ^property_id
    )
    |> set_next_bill(date)

    perform_property(property_id)
  end

  def perform_property(property_id, ids \\ []) do
    property_due_charges(property_id)
    |> Enum.reduce({0, ids}, &bill_tenant/2)
    |> recurse_property(property_id)
  end

  @impl AppCount.Tasks.Worker
  def perform(ids \\ []) do
    due_charges()
    |> Enum.reduce({0, ids}, &bill_tenant/2)
    |> recurse
  end

  defp recurse({0, ids}), do: ids
  defp recurse({_, ids}), do: perform(ids)

  defp recurse_property({0, ids}, _), do: ids
  defp recurse_property({_, ids}, property_id), do: perform_property(property_id, ids)

  def due_charges() do
    current_date =
      AppCount.current_time()
      |> Timex.to_date()

    from(client in AppCount.Public.Client,
      distinct: true,
      select: client.client_schema
    )
    |> Repo.all(prefix: "public")
    |> Enum.reduce([], fn schema, acc ->
      from(
        c in Charge,
        join: l in assoc(c, :lease),
        left_join: h in assoc(l, :charges),
        on:
          h.lease_id == l.id and
            h.charge_code_id == ^Accounting.SpecialAccounts.get_charge_code(:hap_rent).id,
        on: is_nil(h.to_date) or h.to_date >= ^current_date,
        join: u in assoc(l, :unit),
        join: p in assoc(u, :property),
        join: s in assoc(p, :setting),
        join: code in assoc(c, :charge_code),
        left_join: other in Lease,
        on: l.renewal_id == other.id,
        select: %{
          charge_id: c.id,
          charge_code_id: c.charge_code_id,
          code: code.code,
          bill_date: c.next_bill_date,
          amount: c.amount,
          lease_id: c.lease_id,
          end_date: l.end_date,
          move_out: l.actual_move_out,
          from: c.from_date,
          to: c.to_date,
          renewal: other.start_date,
          mtm_fee: s.mtm_fee,
          section_8: max(h.id),
          unit: %{
            id: l.unit_id
          },
          schema: ^schema
        },
        where: c.next_bill_date <= ^current_date and l.start_date <= ^current_date,
        group_by: [c.id, l.id, code.id, other.id, s.id]
      )
      |> Repo.all(prefix: schema)
      |> Enum.reduce(acc, &[&1 | &2])
    end)
  end

  def property_due_charges(property_id) do
    current_date =
      AppCount.current_time()
      |> Timex.to_date()

    from(client in AppCount.Public.Client,
      distinct: true,
      select: client.client_schema
    )
    |> Repo.all(prefix: "public")
    |> Enum.reduce([], fn schema, acc ->
      from(
        c in Charge,
        join: l in assoc(c, :lease),
        left_join: h in assoc(l, :charges),
        on:
          h.lease_id == l.id and
            h.charge_code_id == ^Accounting.SpecialAccounts.get_charge_code(:hap_rent).id,
        join: u in assoc(l, :unit),
        join: p in assoc(u, :property),
        join: s in assoc(p, :setting),
        join: code in assoc(c, :charge_code),
        left_join: renewal in assoc(l, :renewal),
        select: %{
          charge_id: c.id,
          charge_code_id: c.charge_code_id,
          code: code.code,
          bill_date: c.next_bill_date,
          amount: c.amount,
          lease_id: c.lease_id,
          end_date: l.end_date,
          move_out: l.actual_move_out,
          from: c.from_date,
          to: c.to_date,
          renewal: renewal.start_date,
          mtm_fee: s.mtm_fee,
          section_8: max(h.id),
          unit: %{
            id: l.unit_id
          },
          schema: ^schema
        },
        where: c.next_bill_date <= ^current_date and l.start_date <= ^current_date,
        where: u.property_id == ^property_id,
        group_by: [c.id, l.id, code.id, renewal.id, s.id]
      )
      |> Repo.all(prefix: schema)
      |> Enum.reduce(acc, &[&1 | &2])
    end)
  end

  defp bill_tenant(%{} = charge_params, {num_billed, ids}) do
    client_schema = Map.get(charge_params, "schema", "dasmen")
    charge_params = Map.delete(charge_params, "schema")

    adjusted = adj_params(charge_params)

    sum =
      if should_bill(adjusted) do
        {charge_params, add_mtm} = modify_rent(adjusted)

        new_ids =
          charge_params
          |> Map.put(:status, "charge")

        new_ids =
          ClientSchema.new(client_schema, new_ids)
          |> Charges.create_charge()
          |> add_id(ids)

        with_mtm =
          if add_mtm do
            ClientSchema.new(
              client_schema,
              Map.merge(adjusted, %{
                amount: adjusted.mtm_fee,
                status: "charge",
                charge_code_id: Accounting.SpecialAccounts.get_charge_code(:mtm_fees).id
              })
            )
            |> Charges.create_charge()
            |> add_id(new_ids)
          else
            new_ids
          end

        {num_billed + 1, with_mtm}
      else
        {num_billed, ids}
      end

    schedule_next(adjusted.charge_id, adjusted.bill_date)
    sum
  end

  defp add_id({:ok, charge}, ids), do: Enum.concat(ids, [charge.id])
  defp add_id({:error, _}, ids), do: ids
  defp adj_params(%{from: nil} = p), do: adj_params(Map.delete(p, :from))

  defp adj_params(%{bill_date: bill_date, from: f} = p) do
    p
    |> Map.put(:bill_date, max_date(bill_date, f))
    |> Map.delete(:from)
    |> adj_params()
  end

  defp adj_params(params), do: params

  defp schedule_next(%Charge{} = charge, from) do
    next_date =
      AppCount.Jobs.Scheduler.next_ts(charge.schedule, Timex.to_datetime(from))
      |> DateTime.from_unix!()

    charge
    |> Charge.changeset(%{next_bill_date: next_date})
    |> Repo.update()
  end

  defp schedule_next(id, from) do
    Repo.get(Charge, id)
    |> schedule_next(from)
  end

  defp modify_rent(%{amount: a} = p) do
    case days_to_bill(p) do
      {:all, :lease_rent} ->
        {p, false}

      {:all, :mtm_rent} ->
        {Map.put(p, :amount, mtm_rent(p)), p.code == "rent" && is_nil(p.section_8)}

      {lease_days, mtm_days, days_in_month} ->
        lease_amount = prorated_rent(a, lease_days, days_in_month)
        mtm_amount = prorated_rent(mtm_rent(p), mtm_days, days_in_month)

        {
          Map.put(p, :amount, lease_amount + mtm_amount),
          p.code == "rent" && mtm_amount > 0 && is_nil(p.section_8)
        }
    end
  end

  defp modify_rent(params), do: params

  defp days_to_bill(%{
         bill_date: bill_date,
         end_date: end_date,
         move_out: move_out,
         renewal: renewal,
         to: to
       }) do
    month_end =
      Timex.end_of_month(bill_date)
      |> Timex.to_date()

    stop_date =
      cond do
        renewal -> Timex.shift(renewal, days: -1)
        move_out -> move_out
        to -> to
        true -> nil
      end

    days_to_bill =
      cond do
        before?(stop_date, bill_date) ->
          Timex.shift(bill_date, days: -1)

        stop_date && stop_date.month == bill_date.month && stop_date.year == bill_date.year ->
          stop_date

        true ->
          month_end
      end
      |> Timex.diff(bill_date, :days)
      |> Kernel.+(1)

    lease_days =
      cond do
        before?(end_date, bill_date) -> Timex.shift(bill_date, days: -1)
        end_date.month == bill_date.month && end_date.year == bill_date.year -> end_date
        true -> month_end
      end
      |> Timex.diff(bill_date, :days)
      |> Kernel.+(1)

    days_in_month = Timex.days_in_month(bill_date)

    cond do
      #     lease end month - rent is not prorated and mtm is not charged until next month
      Timex.beginning_of_month(end_date) == Timex.beginning_of_month(bill_date) ->
        {:all, :lease_rent}

      lease_days == days_in_month ->
        {:all, :lease_rent}

      days_to_bill - lease_days == days_in_month ->
        {:all, :mtm_rent}

      true ->
        {lease_days, days_to_bill - lease_days, days_in_month}
    end
  end

  defp before?(%Date{} = d1, %Date{} = d2), do: Date.compare(d1, d2) == :lt
  defp before?(_, _), do: false
  defp before_eq?(%Date{} = d1, %Date{} = d2), do: Date.compare(d1, d2) != :gt
  defp before_eq?(_, _), do: false

  defp mtm_rent(%{code: "rent", unit: unit, section_8: nil}),
    do: AppCount.Properties.unit_rent(unit)

  defp mtm_rent(%{amount: amount}), do: amount

  defp prorated_rent(rent, num_days, days_in_month), do: rent / days_in_month * num_days

  defp should_bill(%{
         amount: %{
           coef: 0
         }
       }),
       do: false

  defp should_bill(%{bill_date: date, move_out: m} = b) when not is_nil(m),
    do: before_eq?(date, m) and should_bill(Map.put(b, :move_out, nil))

  defp should_bill(%{bill_date: date, to: to}) when not is_nil(to), do: before_eq?(date, to)
  defp should_bill(%{renewal: nil, move_out: nil}), do: true

  defp should_bill(%{bill_date: date, renewal: renewal, move_out: nil}),
    do: before_eq?(date, renewal)

  defp should_bill(%{bill_date: date, renewal: renewal, move_out: move_out}) do
    # this should never happen to have both a renewal and a move out date--but let's cover it anyway ;)
    before_eq?(date, Enum.min([renewal, move_out]))
  end

  #  defp parse_date(date) when is_binary(date) do
  #    [month, day, year] =
  #      String.split(date, "/")
  #      |> Enum.map(&String.to_integer/1)
  #
  #    %Date{year: year, month: month, day: day}
  #  end
  #
  #  defp parse_date(%Date{} = date), do: date

  defp set_next_bill(query, date) do
    query
    |> update(
      [_, l],
      set: [
        next_bill_date: fragment("GREATEST(?, ?)", l.start_date, ^date)
      ]
    )
    |> Repo.update_all([])
  end

  defp max_date(d1, d2), do: if(Date.compare(d1, d2) == :gt, do: d1, else: d2)
end
