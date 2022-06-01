defmodule AppCount.Accounting.Receipts.Calculator do
  alias AppCount.Accounting.Receipts.ProcessLedger.Charge
  alias AppCount.Accounting.Receipts.ProcessLedger.Concession
  alias AppCount.Accounting.Receipts.ProcessLedger.Payment
  use AppCount.Decimal

  def calculate_receipts(items) do
    {payers, charges} = Enum.split_with(items, &is_payer/1)
    process_items(items, charges, payers, nil, nil, [])
  end

  def process_items(_all_items, charges, payers, _current_start_date, current_stop_date, receipts)
      when (charges == [] or payers == []) and is_nil(current_stop_date) do
    receipts
  end

  def process_items(all_items, charges, payers, _current_start_date, current_stop_date, receipts)
      when charges == [] or payers == [] do
    new_items =
      Enum.filter(
        all_items,
        &(is_nil(&1.until) || Timex.compare(&1.until, current_stop_date, :day) > 0)
      )

    {payers, charges} = Enum.split_with(new_items, &is_payer/1)
    process_items(new_items, charges, payers, current_stop_date, nil, receipts)
  end

  def process_items(
        all_items,
        [charge | charges],
        [payer | payers],
        current_start_date,
        current_stop_date,
        receipts
      ) do
    {payer_balance, charge_balance, receipt} = process_item(payer, charge)
    stop_date = min_stop_date(current_stop_date, charge.until, payer.until)
    new_receipt = Map.merge(receipt, %{stop_date: stop_date, start_date: current_start_date})

    all_items
    |> filter_completed(new_receipt, payer_balance, charge_balance)
    |> process_items(
      new_item_list(charge_balance, charge, charges),
      new_item_list(payer_balance, payer, payers),
      current_start_date,
      stop_date,
      receipts ++ [new_receipt]
    )
  end

  def process_item(%{amount: payer_amount} = payer, %Charge{amount: charge_amount} = charge)
      when payer_amount > charge_amount do
    {payer_amount - charge_amount, nil, receipt_for(charge, payer, charge_amount)}
  end

  def process_item(%{amount: payer_amount} = payer, %Charge{amount: charge_amount} = charge)
      when payer_amount < charge_amount do
    {nil, charge_amount - payer_amount, receipt_for(charge, payer, payer_amount)}
  end

  def process_item(%{amount: payer_amount} = payer, %Charge{amount: charge_amount} = charge)
      when payer_amount == charge_amount do
    {nil, nil, receipt_for(charge, payer, payer_amount)}
  end

  defp is_payer(%Payment{}), do: true
  defp is_payer(%Concession{}), do: true
  defp is_payer(_), do: false

  defp foreign_key(%Concession{}), do: :concession_id
  defp foreign_key(%Payment{}), do: :payment_id

  defp receipt_for(charge, payer, amount) do
    %{charge_id: charge.id, amount: amount}
    |> Map.put(foreign_key(payer), payer.id)
  end

  defp new_item_list(nil, _old_item, old_list), do: old_list

  defp new_item_list(balance, old_item, old_list),
    do: [Map.put(old_item, :amount, balance) | old_list]

  defp min_stop_date(nil, nil, nil), do: nil

  defp min_stop_date(current, date1, date2) do
    [current, date1, date2]
    |> Enum.filter(& &1)
    |> Enum.min(Date)
  end

  defp filter_completed(
         items,
         %{stop_date: nil, concession_id: id} = receipt,
         nil,
         charge_balance
       ) do
    Enum.filter(
      items,
      fn
        %Concession{id: concession_id} -> concession_id != id
        _ -> true
      end
    )
    |> filter_completed(receipt, 0, charge_balance)
  end

  defp filter_completed(items, %{stop_date: nil, payment_id: id} = receipt, nil, charge_balance) do
    Enum.filter(
      items,
      fn
        %Payment{id: payment_id} -> payment_id != id
        _ -> true
      end
    )
    |> filter_completed(receipt, 0, charge_balance)
  end

  defp filter_completed(items, %{stop_date: nil, charge_id: id}, _payer_balance, nil) do
    Enum.filter(
      items,
      fn
        %Charge{id: charge_id} -> charge_id != id
        _ -> true
      end
    )
  end

  defp filter_completed(items, _receipt, _payer_balance, _charge_balance), do: items
end
