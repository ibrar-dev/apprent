defmodule BlueMoon.Data.Params do
  alias BlueMoon.Data.Lease

  def to_params(xml) do
    %{STANDARD: data, CUSTOM: custom} =
      BlueMoon.Utils.xml_to_map(xml, SweetXml.sigil_x("//LEASE"))[:LEASE]

    washer_type =
      cond do
        data[:"WASHER-DRYER-FULL-SIZE"] == "T" -> "Full Size"
        data[:"WASHER-DRYER-STACKABLE"] == "T" -> "Stackable"
        true -> nil
      end

    deposit_params =
      cond do
        !!data[:"SECURITY-DEPOSIT"] ->
          %{deposit_type: "deposit", deposit_value: data[:"SECURITY-DEPOSIT"]}

        !!data[:"SPECIAL-PROVISIONS"] and
            String.match?(data[:"SPECIAL-PROVISIONS"], ~r"Non Refundable Bond") ->
          %{
            deposit_type: "bond",
            deposit_value: Enum.at(String.split(data[:"SECURITY-DEPOSIT"], "- $"), 1)
          }

        !!data[:"SPECIAL-PROVISIONS"] and
            String.match?(data[:"SPECIAL-PROVISIONS"], ~r"ePremium Account Number") ->
          %{
            deposit_type: "epremium",
            deposit_value: Enum.at(String.split(data[:"SPECIAL-PROVISIONS"], "- "), 1)
          }

        true ->
          %{}
      end

    concession_months =
      if data[:"ADDENDUM-RENT-CONCESSION-ONE-TIME-MONTHS"],
        do: String.split(data[:"ADDENDUM-RENT-CONCESSION-ONE-TIME-MONTHS"], ","),
        else: []

    %{
      rent: data[:RENT],
      start_date: parse_date(data[:"LEASE-BEGIN-DATE"]),
      end_date: parse_date(data[:"LEASE-END-DATE"]),
      lease_date: parse_date(data[:"DATE-OF-LEASE"]),
      unit_keys: data[:"NUMBER-OF-APARTMENT-KEYS"],
      mail_keys: data[:"NUMBER-OF-MAIL-KEYS"],
      other_keys: data[:"NUMBER-OF-OTHER-KEYS"],
      buy_out_fee: data[:"EARLY-TERMINATION-FEE"],
      concession_fee: data[:"EARLY-TERMINATION-TOTAL-FEE"],
      gate_access_card: convert_bool(data[:"REMOTE-CARD-CODE-ADDENDUM-CARD"]),
      gate_access_remote: convert_bool(data[:"REMOTE-CARD-CODE-ADDENDUM-REMOTE"]),
      gate_access_code: convert_bool(data[:"REMOTE-CARD-CODE-ADDENDUM-CODE"]),
      lost_remote_fee: convert_bool(data[:"REMOTE-CARD-CODE-ADDENDUM-LOST-REMOTE"]),
      lost_card_fee: convert_bool(data[:"REMOTE-CARD-CODE-ADDENDUM-LOST-CARD"]),
      code_change_fee: convert_bool(data[:"REMOTE-CARD-CODE-ADDENDUM-CODE-CHANGE"]),
      insurance_company: data[:"RENTERS-INSURANCE-PROVIDER"],
      monthly_discount: data[:"ADDENDUM-RENT-CONCESSION-AMOUNT"],
      one_time_concession: data[:"ADDENDUM-RENT-CONCESSION-ONE-TIME-AMOUNT"],
      concession_months: concession_months,
      other_discount: data[:"ADDENDUM-RENT-CONCESSION-DESCRIPTION"],
      washer_rent: data[:"WASHER-DRYER-FEE"],
      washer_type: washer_type,
      washer_serial: data[:"WASHER-MODEL-SERIAL-NUMBER"],
      dryer_serial: data[:"DRYER-MODEL-SERIAL-NUMBER"],
      smart_fee: custom[:"SMART-FEE"],
      waste_cost: custom[:"WASTE-FEE"],
      bug_inspection: data[:"BED-BUG-ADDENDUM-INSPECTION"],
      bug_infestation: data[:"BED-BUG-ADDENDUM-INFESTATION"],
      bug_disclosure: data[:"BED-BUG-ADDENDUM-INFESTATION-DISCLOSURE"],
      fitness_card_numbers: parse_array("COMMUNITY-FITNESS-CENTER-CARD", data),
      residents: parse_array("RESIDENT", data),
      occupants: parse_array("OCCUPANT", data),
      unit: data[:"UNIT-NUMBER"]
    }
    |> Map.merge(deposit_params)
    |> Lease.cast_params()
  end

  defp parse_array(name, data), do: parse_array(name, data, [], 2, data[:"#{name}-1"])
  defp parse_array(_, _, list, _, nil), do: list

  defp parse_array(name, data, list, index, last) do
    parse_array(name, data, list ++ [last], index + 1, data[:"#{name}-#{index}"])
  end

  def parse_date(raw),
    do:
      Timex.parse!(raw, "{M}/{D}/{YYYY}")
      |> Timex.to_date()

  defp convert_bool("T"), do: true
  defp convert_bool("F"), do: false
end
