defmodule AppCount.Leasing.MonthlyCharges.Compute do
  alias AppCount.Ledgers.Utils.SpecialChargeCodes

  def bill_tenant(%{} = charge_params, current_month_start) do
    bill_date =
      Enum.max([current_month_start, charge_params.from || charge_params.lease_start], Date)

    adjusted = Map.merge(charge_params, %{bill_date: bill_date, status: "charge"})

    if should_bill(adjusted) do
      {charge_params, add_mtm} = modify_rent(adjusted)

      full_charge_params = Map.merge(charge_params, %{bill_date: bill_date, status: "charge"})

      if add_mtm do
        mtm =
          adjusted
          |> Map.merge(%{
            amount: adjusted.mtm_fee,
            charge_code_id: SpecialChargeCodes.get_charge_code(:mtm_fees).id,
            bill_date: bill_date,
            status: "charge"
          })

        [full_charge_params, mtm]
      else
        full_charge_params
      end
    else
      []
    end

    #    schedule_next(adjusted.charge_id, adjusted.bill_date)
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
         renewal: renewal,
         to: to
       }) do
    month_end =
      Timex.end_of_month(bill_date)
      |> Timex.to_date()

    stop_date =
      cond do
        renewal -> Timex.shift(renewal, days: -1)
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

  defp mtm_rent(%{is_rent_charge: true, unit_id: unit_id, section_8: nil}) do
    AppCount.Properties.unit_rent(%{id: unit_id})
    |> Decimal.to_float()
  end

  defp mtm_rent(%{amount: amount}), do: amount

  defp prorated_rent(rent, num_days, days_in_month),
    do: round_to_currency(rent / days_in_month * num_days)

  defp should_bill(%{amount: %{coef: 0}}), do: false
  defp should_bill(_), do: true

  defp round_to_currency(decimal) when is_float(decimal), do: Float.round(decimal, 2)
  defp round_to_currency(int) when is_integer(int), do: int
end
