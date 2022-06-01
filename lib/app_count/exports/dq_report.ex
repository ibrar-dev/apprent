defmodule AppCount.Exports.DQReport do
  alias AppCount.Excel
  alias AppCount.Reports

  def dq_report_excel(property_id, filters, ar, date \\ nil) do
    filters = String.split(filters, ",")

    Reports.delinquency_report(property_id, date)
    |> Enum.filter(fn t -> t.owed > 0 && t.status in filters end)
    |> build_detail(ar)
    |> Excel.to_workbook()
  end

  defp build_detail(data, ar) do
    %{running_data: running_data, totals: totals} =
      Enum.reduce(data, %{running_data: [], totals: [0, 0, 0, 0]}, &add_row_detail(&1, &2, ar))

    [
      %{
        data: Enum.sort(running_data),
        name: "DQ Report",
        table_head: [
          "Unit",
          "ID",
          "Resident",
          "Status",
          "Total Owed",
          "0-30 days",
          "31-60 days",
          "61-90 days",
          "Over 90 days"
        ],
        table_footer: [
          "",
          "",
          "",
          "",
          Enum.sum(totals),
          Enum.at(totals, 0),
          Enum.at(totals, 1),
          Enum.at(totals, 2),
          Enum.at(totals, 3)
        ],
        widths: [15, 15, 30, 15, 15, 15, 15, 15, 15]
      }
    ]
  end

  defp get_level(days_late) do
    cond do
      days_late < 31 -> 0
      days_late < 61 -> 1
      days_late < 91 -> 2
      true -> 3
    end
  end

  defp breakdown(%{:charges => charges, :owed => owed}, ar) do
    charges =
      if ar == "true", do: Enum.filter(charges, fn c -> c["account"] == "Rent" end), else: charges

    Enum.reduce(charges, %{break: [0, 0, 0, 0], balance: owed}, fn charge, sums ->
      if sums.balance <= 0 do
        sums
      else
        amount = if charge["amount"] > sums.balance, do: sums.balance, else: charge["amount"]
        level = get_level(charge["days_late"])
        new_break = List.replace_at(sums.break, level, Enum.at(sums.break, level) + amount)
        Map.merge(sums, %{break: new_break, balance: sums.balance - charge["amount"]})
      end
    end)
  end

  defp add_row_detail(data, %{running_data: running_data, totals: totals}, ar) do
    %{break: break, balance: _balance} = breakdown(data, ar)

    new_totals =
      Stream.with_index(totals)
      |> Enum.map(fn {t, idx} ->
        t + Enum.at(break, idx)
      end)

    new_row = [
      data.unit,
      data.tenant_id,
      data.tenant,
      data.status,
      convert_decimal_to_float(Enum.sum(break)),
      convert_decimal_to_float(Enum.at(break, 0)),
      convert_decimal_to_float(Enum.at(break, 1)),
      convert_decimal_to_float(Enum.at(break, 2)),
      convert_decimal_to_float(Enum.at(break, 3))
    ]

    %{running_data: running_data ++ [new_row], totals: new_totals}
  end

  defp convert_decimal_to_float(num), do: %{data: num, styles: ["currency", "align-right"]}
end
