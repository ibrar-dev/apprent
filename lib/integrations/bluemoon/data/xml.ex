defmodule BlueMoon.Data.Xml do
  use AppCount.Decimal

  def to_xml(params) do
    {standard_params(params), custom_params(params)}
  end

  defp standard_params(params) do
    {total, prorated} = calculate_rent(params)

    [
      {"RENT", total},
      {"PRORATED-RENT", prorated},
      {"UNIT-NUMBER", params.unit},
      {"LEASE-BEGIN-DATE", format_date(params.start_date)},
      {"LEASE-END-DATE", format_date(params.end_date)},
      {"DATE-OF-LEASE", format_date(params.lease_date)},
      {"NUMBER-OF-APARTMENT-KEYS", params.unit_keys},
      {"NUMBER-OF-MAIL-KEYS", params.mail_keys},
      {"NUMBER-OF-OTHER-KEYS", params.other_keys},
      {"EARLY-TERMINATION-FEE", params.buy_out_fee},
      {"EARLY-TERMINATION-TOTAL-FEE", params.concession_fee},
      {"REMOTE-CARD-CODE-ADDENDUM-CARD", convert_bool(params.gate_access_card)},
      {"REMOTE-CARD-CODE-ADDENDUM-REMOTE", convert_bool(params.gate_access_remote)},
      {"REMOTE-CARD-CODE-ADDENDUM-CODE", convert_bool(params.gate_access_code)},
      {"REMOTE-CARD-CODE-ADDENDUM-LOST-REMOTE", convert_bool(params.lost_remote_fee)},
      {"REMOTE-CARD-CODE-ADDENDUM-LOST-CARD", convert_bool(params.lost_card_fee)},
      {"REMOTE-CARD-CODE-ADDENDUM-CODE-CHANGE", convert_bool(params.code_change_fee)},
      {"RENTERS-INSURANCE-PROVIDER", params.insurance_company},
      {"ADDENDUM-RENT-CONCESSION-AMOUNT", params.monthly_discount},
      {"ADDENDUM-RENT-CONCESSION-ONE-TIME-AMOUNT", params.one_time_concession},
      {"ADDENDUM-RENT-CONCESSION-ONE-TIME-MONTHS", Enum.join(params.concession_months, ",")},
      {"ADDENDUM-RENT-CONCESSION-DESCRIPTION", params.other_discount},
      {"WASHER-DRYER-FEE", params.washer_rent},
      {"WASHER-MODEL-SERIAL-NUMBER", params.washer_serial},
      {"DRYER-MODEL-SERIAL-NUMBER", params.dryer_serial},
      {"BED-BUG-ADDENDUM-INSPECTION", params.bug_inspection},
      {"BED-BUG-ADDENDUM-INFESTATION", params.bug_infestation},
      {"BED-BUG-ADDENDUM-INFESTATION-DISCLOSURE", params.bug_disclosure},
      get_security(params)
    ]
    |> Enum.concat(parse_array(Enum.map(params.residents, & &1.name), "RESIDENT"))
    |> Enum.concat(parse_array(params.occupants, "OCCUPANT"))
    |> Enum.concat(parse_array(params.fitness_card_numbers, "COMMUNITY-FITNESS-CENTER-CARD"))
    |> Enum.concat(washer_values(params))
  end

  defp custom_params(params) do
    [
      {"SMART-FEE", params.smart_fee},
      {"WASTE-FEE", params.waste_cost}
    ]
  end

  defp calculate_rent(%{start_date: start_date, rent: rent}) do
    total = AppCount.Decimal.Float.to_printable(rent)
    days = Date.days_in_month(start_date)
    {day, _} = Integer.parse(Timex.format!(start_date, "{D}"))
    # includes fix for broken Decimal stuff :(
    prorated = Float.ceil(rent / days * (days - day + 1) - 0.0000000000001, 2)
    {total, AppCount.Decimal.Float.to_printable(prorated)}
  end

  defp get_security(%{deposit_type: "deposit", deposit_value: val}) do
    {"SECURITY-DEPOSIT", val}
  end

  defp get_security(%{deposit_type: "bond", deposit_value: val}) do
    {
      "SPECIAL-PROVISIONS",
      "All communication with Agent for Owner must be conducted via writing. Non Refundable Bond - $#{
        val
      }"
    }
  end

  defp get_security(%{deposit_type: "epremium", deposit_value: val}) do
    {
      "SPECIAL-PROVISIONS",
      "All communication with Agent for Owner must be conducted via writing. ePremium Account Number - #{
        val
      }"
    }
  end

  defp get_security(_) do
    {"SPECIAL-PROVISIONS",
     "All communication with Agent for Owner must be conducted via writing."}
  end

  defp washer_values(%{washer_type: w}) when w in ["Full Stack", "Stackable"] do
    param =
      w
      |> String.replace(" ", "-")
      |> String.upcase()

    [{"WASHER-DRYER-OTHER", "F"}, {"WASHER-DRYER-#{param}", "T"}]
  end

  defp washer_values(%{washer_type: w}) do
    [{"WASHER-DRYER-OTHER-DESC", w}, {"WASHER-DRYER-OTHER", "T"}]
  end

  defp parse_array(list, name) do
    list
    |> Enum.with_index(1)
    |> Enum.map(fn {el, index} ->
      {"#{name}-#{index}", el}
    end)
  end

  defp convert_bool(true), do: "T"
  defp convert_bool(false), do: "F"

  defp format_date(date), do: Timex.format!(date, "{M}/{D}/{YYYY}")
end
