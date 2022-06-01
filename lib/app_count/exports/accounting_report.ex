defmodule AppCount.Exports.AccountingReport do
  import Ecto.Query
  alias AppCount.Excel
  alias AppCount.Reports
  alias AppCount.Properties.Property

  def accounting_report_excel(id, property_ids, book, suppress_zeros, start_date, end_date \\ nil) do
    properties =
      from(p in Property, where: p.id in ^property_ids, select: p.name)
      |> AppCount.Repo.all()

    report =
      Reports.run_report(
        id,
        %{property_ids: property_ids, book: book, start_date: start_date, end_date: end_date}
      )

    binary = [
      %{
        data: formatted_data(report, suppress_zeros, 0),
        name: sheet_name(id),
        sheet_headers: [sheet_name(id), sheet_date()] ++ properties,
        table_footer: [],
        table_head: table_headers(id, start_date, end_date),
        widths: [
          50,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15,
          15
        ]
      }
    ]

    %{
      binary: Excel.to_workbook(binary),
      name: sheet_name(id, properties, start_date, end_date) <> ".xlsx"
    }
  end

  defp formatted_data(report_data, sz, level),
    do: Enum.reduce(report_data, [], &process_group(&1, &2, sz, level))

  defp process_group(group, acc, false, level), do: do_process_group(group, acc, false, level)
  defp process_group(%{year_total: 0}, acc, true, _level), do: acc

  defp process_group(%{year_total: _} = group, acc, true, level),
    do: do_process_group(group, acc, true, level)

  defp process_group(%{total: 0}, acc, true, _level), do: acc
  defp process_group(group, acc, true, level), do: do_process_group(group, acc, true, level)

  defp do_process_group(%{name: name, accounts: accounts, groups: groups} = p, acc, sz, lvl) do
    category = [[bold(level(name, lvl))]]

    acc ++
      category ++
      formatted_data(groups, sz, lvl + 1) ++
      format_accounts(accounts, sz, lvl) ++ total_line(p, lvl)
  end

  defp format_accounts(accounts, sz, lvl),
    do: Enum.reduce(accounts, [], &format_account(&1, &2, sz, lvl))

  defp format_account([_num, _name, a, _account_id], acc, true, _) when a == 0, do: acc
  defp format_account([_num, _name, a, _account_id, b], acc, true, _) when a + b == 0, do: acc

  defp format_account([num, name, total, _account_id], acc, _, lvl),
    do: acc ++ [[level("#{num} - #{name}", lvl + 1), curr(total)]]

  defp format_account([num, name, total, _account_id, ytd], acc, _, lvl),
    do: acc ++ [[level("#{num} - #{name}", lvl + 1), curr(total), curr(ytd)]]

  defp format_account([num, name, _account_id | nums], acc, _, lvl),
    do: acc ++ [[level("#{num} - #{name}", lvl + 1)] ++ Enum.map(nums, &curr/1)]

  defp format_account(%{total: a, ytd: b}, acc, true, _) when a + b == 0, do: acc

  defp format_account(%{name: name, total: total, ytd: ytd}, acc, _, lvl),
    do: acc ++ [[bold(level("Total #{name}:", lvl)), bold_curr(total), bold_curr(ytd)]]

  defp format_account(%{name: name, totals: totals}, acc, _, lvl),
    do: acc ++ [[bold(level("Total #{name}:", lvl))] ++ Enum.map(totals, &bold_curr/1)]

  defp total_line(%{name: name, total: totals}, lvl) when is_list(totals),
    do: [[bold(level("Total: #{name}", lvl))] ++ Enum.map(totals, &bold_curr/1)]

  defp total_line(%{name: name, total: total, year_total: ytd}, lvl),
    do: [[bold(level("Total: #{name}", lvl)), bold_curr(total), bold_curr(ytd)]]

  defp total_line(%{name: name, total: total}, lvl),
    do: [[bold(level("Total #{name}:", lvl)), bold_curr(total)]]

  defp sheet_date(), do: format_date(AppCount.current_date())

  defp sheet_name(id, properties, start_date, nil),
    do: "#{sheet_name(id)} #{hd(properties)} #{start_date}"

  defp sheet_name(id, properties, start_date, end_date),
    do: "#{sheet_name(id, properties, start_date, nil)} - #{end_date}"

  defp sheet_name("balance"), do: "Balance Sheet"
  defp sheet_name("income"), do: "Income Statement"
  defp sheet_name("gl"), do: "General Ledger"
  defp sheet_name("t12"), do: "12 Month Income"

  defp table_headers("balance", _, _), do: ["Account", "Period to Date"]
  defp table_headers("income", _, _), do: ["Account", "Period to Date", "Year to Date"]
  defp table_headers("gl", _, _), do: "General Ledger"

  defp table_headers("t12", start_date, end_date) do
    start_date = Date.from_iso8601!(start_date)
    end_date = Date.from_iso8601!(end_date)

    Enum.reduce(
      0..Timex.diff(end_date, start_date, :month),
      ["Account"],
      fn num, acc ->
        month =
          Timex.shift(start_date, months: num)
          |> Timex.format!("{Mshort} {YYYY}")

        acc ++ [month]
      end
    )
    |> Enum.concat(["Total"])
  end

  defp format_date(date) when is_binary(date), do: format_date(Date.from_iso8601!(date))
  defp format_date(date), do: Timex.format!(date, "{M}/{D}/{YYYY}")

  defp bold(data), do: %{data: data, styles: ["bold"]}
  defp curr(data), do: %{data: data, styles: ["currency"]}
  defp bold_curr(data), do: %{data: data, styles: ["bold", "currency"]}
  defp level(data, lvl), do: String.duplicate("    ", lvl) <> data
end
