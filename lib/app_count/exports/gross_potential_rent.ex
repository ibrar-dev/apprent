defmodule AppCount.Exports.GrossPotentialRentExcel do
  alias AppCount.Excel
  alias AppCount.Reports
  use AppCount.Decimal
  @starting_totals for _ <- 1..11, do: 0

  def run(property_id, date, post_month) do
    %{running_data: running_data, totals: totals} =
      Enum.reduce(
        Reports.gross_potential_rent(property_id, date, post_month),
        %{running_data: [], totals: @starting_totals},
        &add_row_detail(&1, &2)
      )

    [
      %{
        data: running_data,
        name: "GPR Report",
        sheet_headers: [
          "Gross Potential Rent",
          AppCount.Repo.get(AppCount.Properties.Property, property_id).name,
          "As of: #{date}",
          "Post Month: #{post_month}"
        ],
        table_head: [
          "Unit",
          "Floor Plan",
          "Resident",
          "Market Rent",
          "Loss/Gain to Lease",
          "Potential Rent",
          "Vacancy",
          "Actual Rent",
          "Concession",
          "Rental Income",
          "Receipts Current",
          "Receipts Prior",
          "Delinquency",
          "Prepay"
        ],
        table_footer: totals,
        widths: [15, 20, 30, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20]
      }
    ]
    |> Excel.to_workbook(fast: true)
  end

  defp add_row_detail(%{total: true, type: "main", next_group: ng} = row, %{
         running_data: data,
         totals: totals
       }) do
    row =
      [
        "Totals:",
        "",
        "",
        row.market_rent,
        row.market_rent - row.rent,
        row.rent,
        row.rent - row.actual_rent,
        row.actual_rent || 0,
        row.concession || 0,
        row.actual_rent + row.concession,
        row.receipts_current,
        row.receipts_prior,
        row.delinquency,
        row.balance
      ]
      |> Enum.map(&%{data: &1, styles: ["bold", "border-top", "currency"]})

    %{running_data: data ++ [row, [], table_heading(ng)], totals: totals}
  end

  defp add_row_detail(%{total: true, type: "down", next_group: ng} = row, %{
         running_data: data,
         totals: totals
       }) do
    row =
      Enum.map(
        ["Total", "Down", "", row.market_rent, "", "", "", "", "", "", "", "", "", ""],
        &%{data: &1, styles: ["bold", "border-top", "currency"]}
      )

    %{running_data: data ++ [row, [], table_heading(ng)], totals: totals}
  end

  defp add_row_detail(%{total: true, type: "future"} = row, %{running_data: data, totals: totals}) do
    row =
      Enum.map(
        [
          "Total",
          "Future Residents",
          "",
          row.market_rent,
          row.market_rent - row.rent,
          row.rent,
          row.rent - row.actual_rent,
          row.actual_rent || 0,
          row.concession || 0,
          row.actual_rent + row.concession,
          row.receipts_current,
          row.receipts_prior,
          row.delinquency,
          row.balance
        ],
        &%{data: &1, styles: ["bold", "border-top", "currency"]}
      )

    %{running_data: data ++ [row], totals: totals}
  end

  defp add_row_detail(%{total: true} = row, %{running_data: data, totals: _}) do
    %{
      running_data: data,
      totals: [
        "Totals:",
        "",
        "",
        row.market_rent,
        row.market_rent - row.rent,
        row.rent,
        row.rent - row.actual_rent,
        row.actual_rent || 0,
        row.concession || 0,
        row.actual_rent + row.concession,
        row.receipts_current,
        row.receipts_prior,
        row.delinquency,
        row.balance
      ]
    }
  end

  defp add_row_detail(%{status: "DOWN"} = row, %{running_data: data, totals: totals}) do
    data =
      data ++
        [
          [
            row.number,
            row.floor_plan,
            "",
            curr(row.market_rent)
          ]
        ]

    %{running_data: data, totals: totals}
  end

  defp add_row_detail(row, %{running_data: data, totals: totals}) do
    data =
      data ++
        [
          [
            row.number,
            row.floor_plan,
            "#{row.tenant["first_name"]} #{row.tenant["last_name"]}",
            curr(row.market_rent),
            curr(row.market_rent - row.rent),
            curr(row.rent),
            curr(row.rent - row.actual_rent),
            curr(row.actual_rent || 0),
            curr(row.concession || 0),
            curr(row.actual_rent + row.concession),
            curr(row.receipts_current),
            curr(row.receipts_prior),
            curr(row.delinquency),
            curr(row.balance)
          ]
        ]

    %{running_data: data, totals: totals}
  end

  defp curr(num) do
    %{data: num, styles: ["currency"]}
  end

  defp table_heading("down"), do: [%{data: "Non-Revenue Units", styles: ["bold"]}]

  defp table_heading("future"),
    do: [%{data: "Future Residents That Have Not Moved In", styles: ["bold"]}]

  defp table_heading("final"), do: []
end
