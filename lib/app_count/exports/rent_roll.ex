defmodule AppCount.Exports.RentRoll do
  alias AppCount.Repo
  alias AppCount.Excel
  alias AppCount.Reports
  alias AppCount.Properties
  use AppCount.Decimal

  @potent_dict %{
    "Application Fees Income" => 0,
    "Administration Fees Income" => 1,
    "Security Deposit" => 2
  }

  def rent_roll_excel(admin, property_id, date \\ nil) do
    rent_roll = Reports.RentRoll.rent_roll(admin, property_id, date)
    property = Repo.get(Properties.Property, property_id)

    Excel.to_workbook([
      build_real(property, date, rent_roll["rent_roll_real"], rent_roll["totals"]),
      build_potent(property, date, rent_roll["rent_roll_potent"], rent_roll["totals"]),
      build_summary(property, date, rent_roll["charges_summary"], rent_roll["totals"])
    ])
  end

  defp build_real(property, date, real, %{"real" => totals}) do
    %{
      data: Enum.map(real, &add_row_real/1),
      name: "Current Residents",
      sheet_headers: [
        "Rent Roll with Lease Charges",
        property.name,
        "#{date || AppCount.current_date()}"
      ],
      table_head: [
        "Unit",
        "Floor Plan",
        "Sq Ft",
        "Resident",
        "Name",
        "Market Rent",
        "Charges",
        "Amount",
        "Deposit",
        "Move In",
        "Lease End",
        "Move Out",
        "Balance"
      ],
      table_footer: [
        "Totals",
        "Units: #{totals.units}",
        "Sq Footage: #{totals.sq_ft}",
        "",
        "",
        "Market Rent: #{totals.mr}",
        "",
        "Lease Charges: #{totals.lc}",
        "Deposits: #{totals.sd}",
        "",
        "",
        "",
        "Balance: #{totals.balance}"
      ],
      widths: [13, 21, 13, 13, 30, 13, 18, 13, 13, 13, 13, 13, 13]
    }
  end

  defp build_summary(property, date, summary, totals) do
    %{
      data: Enum.map(summary, &add_row_summary/1),
      name: "Charges Summary",
      sheet_headers: [
        "Rent Roll with Lease Charges",
        property.name,
        "#{date || AppCount.current_date()}",
        "Summary of Charges"
      ],
      table_head: ["Account", "Amount"],
      table_footer: ["Total", totals["charges"]],
      widths: [28, 20]
    }
  end

  defp build_potent(property, date, potent, %{"potent" => totals}) do
    %{
      data: Enum.map(potent, &add_row_potent/1),
      name: "Future Residents and Applicants",
      sheet_headers: [
        "Rent Roll with Lease Charges",
        property.name,
        "#{date || AppCount.current_date()}"
      ],
      table_head: [
        "Applicant",
        "Applicant ID",
        "Unit",
        "Floor Plan",
        "Sq Footage",
        "Charges",
        "Amount",
        "Date Applied",
        "Status"
      ],
      table_footer: [
        "Applicants: #{totals.applicants}",
        "",
        "",
        "",
        "Sq Footage: #{totals.sq_ft}",
        "",
        "Amount: #{totals.charges}"
      ],
      widths: [22, 13, 15, 21, 13, 18, 13, 13, 13]
    }
  end

  defp add_row_potent(row) do
    amounts =
      Enum.reduce(
        row.payments,
        [0, 0, 0],
        fn %{"amount" => amount, "account" => account}, a ->
          case @potent_dict[account] do
            nil -> a
            index -> List.replace_at(a, index, amount)
          end
        end
      )

    [
      row.name,
      row.application_id,
      row.number,
      row.floor_plan,
      row.sq_footage,
      [
        "Application Fee",
        "Administration Fee",
        "Deposit",
        %{data: "Total: ", styles: ["bold", "border-top"]}
      ],
      Enum.map(amounts, &%{data: &1, styles: ["currency"]}) ++
        [
          %{data: Enum.sum(amounts), styles: ["bold", "border-top", "currency"]}
        ],
      convert_date(row.date),
      row.status
    ]
  end

  defp add_row_summary(row) do
    [row.account, convert_decimal_to_float(row.total)]
  end

  defp add_row_real(%{charges: charges} = row) do
    total = Enum.reduce(charges, 0, fn c, acc -> acc + c["amount"] end)

    [
      row.number,
      row.floor_plan,
      row.sq_footage,
      row.tenant_id,
      row.resident,
      convert_decimal_to_float(row.market_rent),
      Enum.map(charges, & &1["account"]) ++ [%{data: "Total:", styles: ["bold", "border-top"]}],
      Enum.map(charges, &convert_decimal_to_float(&1["amount"])) ++
        [
          %{data: total, styles: ["bold", "border-top", "currency", "align-right"]}
        ],
      convert_decimal_to_float(row.deposit_amount),
      convert_date(row.actual_move_in),
      convert_date(row.end_date),
      convert_date(row.move_out_date),
      convert_decimal_to_float(row.balance)
    ]
  end

  defp convert_decimal_to_float(%Decimal{} = num),
    do: convert_decimal_to_float(Decimal.to_float(num))

  defp convert_decimal_to_float(num) when is_nil(num), do: convert_decimal_to_float(0)
  defp convert_decimal_to_float(num), do: %{data: num, styles: ["currency", "align-right"]}

  defp convert_date(date) when is_nil(date), do: ""
  defp convert_date(date), do: Timex.format!(date, "%Y-%m-%d", :strftime)
end
