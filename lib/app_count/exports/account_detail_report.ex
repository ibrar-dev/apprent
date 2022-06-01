defmodule AppCount.Exports.AccountDetailReport do
  alias AppCount.Excel

  def account_detail_excel(params, name, title) do
    unpacked =
      params
      |> Map.values()
      |> List.flatten()

    {Excel.to_workbook([build_detail(unpacked, title, name)], fast: true), title}
  end

  defp debit_credit(excel_row, type, amount) when type == "credit",
    do: List.replace_at(excel_row, 4, amount)

  defp debit_credit(excel_row, _type, amount), do: List.replace_at(excel_row, 3, amount)

  defp add_row_detail(row, acc) do
    new_row =
      [
        convert_date(row.date),
        convert_date(row.post_month),
        %{data: row.desc, styles: ["wrap"]},
        nil,
        nil,
        convert_decimal_to_float(row.running_total)
      ]
      |> debit_credit(row.type, row.amount)

    totals =
      if row.type === "credit" do
        %{credit: acc.credit + row.amount}
      else
        %{debit: acc.debit + row.amount}
      end

    Map.merge(acc, %{running_data: acc.running_data ++ [new_row], balance: row.running_total})
    |> Map.merge(totals)
  end

  defp build_footer(type, balance) do
    Enum.map(
      0..5,
      fn x ->
        case x do
          2 ->
            %{data: type, styles: ["bold", "bg_header"]}

          5 ->
            %{
              data: no_style_decimal_to_float(balance),
              styles: ["bold", "bg_header", "currency", "align-right"]
            }

          _ ->
            %{data: "", styles: ["bold", "bg_header"]}
        end
      end
    )
  end

  defp build_footer(type, credit, debit) do
    Enum.map(
      0..5,
      fn x ->
        case x do
          2 ->
            %{data: type, styles: ["bold", "bg_header"]}

          3 ->
            %{
              data: no_style_decimal_to_float(debit),
              styles: ["bold", "bg_header", "currency", "align-right"]
            }

          4 ->
            %{
              data: no_style_decimal_to_float(credit),
              styles: ["bold", "bg_header", "currency", "align-right"]
            }

          _ ->
            %{data: "", styles: ["bold", "bg_header"]}
        end
      end
    )
  end

  defp build_detail(params, title, name) do
    %{:running_data => running_data, :balance => balance, :credit => credit, :debit => debit} =
      Enum.reduce(
        params,
        %{running_data: [], balance: 0, credit: 0, debit: 0},
        &add_row_detail(&1, &2)
      )

    %{
      data:
        running_data ++
          [build_footer("Totals", credit, debit)] ++ [build_footer("Running Total", balance)],
      name: name,
      sheet_headers: title,
      table_head: [
        "Date",
        "Post Month",
        "Desc",
        "Debit",
        "Credit",
        "Balance"
      ],
      widths: [15, 15, 80, 15, 15, 18]
    }
  end

  defp no_style_decimal_to_float(%Decimal{} = num),
    do: no_style_decimal_to_float(Decimal.to_float(num))

  defp no_style_decimal_to_float(num), do: num

  defp convert_decimal_to_float(%Decimal{} = num),
    do: convert_decimal_to_float(Decimal.to_float(num))

  defp convert_decimal_to_float(num) when is_nil(num), do: convert_decimal_to_float(0)
  defp convert_decimal_to_float(num), do: %{data: num, styles: ["currency", "align-right"]}

  defp convert_date(date) when is_nil(date), do: ""
  defp convert_date(date), do: Timex.format!(date, "%Y-%m-%d", :strftime)
end
