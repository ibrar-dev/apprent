defmodule Payscape.CreateTransaction do
  import XmlBuilder
  use AppCount.Decimal

  def request(amount, source, processor) do
    document([
      doctype("Request.dtd", system: ""),
      element(
        :XMLRequest,
        [
          element(:certStr, hd(processor.keys)),
          element(:termid, Enum.at(processor.keys, 1)),
          element(:class, "partner"),
          transaction(amount, source, processor)
        ]
      )
    ])
  end

  # Format ACH transaction information as XML
  #
  # Docs: https://www.propay.com/en-US/Documents/API-Docs/ProPay-API-Manual-XML
  defp transaction(amount, %{type: "ba"} = ba, processor) do
    account_name = formatted_account_name(ba.name)

    element(
      :XMLTrans,
      [
        element(:transType, "36"),
        element(:amount, trunc(amount * 100)),
        element(:accountNum, Enum.at(processor.keys, 2)),
        element(:RoutingNumber, ba.num2),
        element(:AccountNumber, ba.num1),
        element(:accountType, formatted_subtype(ba)),
        element(:StandardEntryClassCode, "WEB"),
        element(:accountName, account_name)
      ]
    )
  end

  defp formatted_subtype(%{subtype: nil}) do
    "Checking"
  end

  defp formatted_subtype(%{subtype: ""}) do
    "Checking"
  end

  defp formatted_subtype(%{subtype: subtype}) do
    String.capitalize(subtype)
  end

  # Per Payscape's documentation, we can only send in alphanumeric characters
  # and spaces (no diacritical marks, unfortunately), and we can only send in a
  # name of up to 31 characters (hard max of 32). Thus, we do that formatting.
  defp formatted_account_name(account_name) do
    strip_and_truncate(account_name, 31)
  end

  # Strip out all non-alpha-numeric characters (and spaces), then trim to length
  defp strip_and_truncate(str, max_length) do
    str
    |> String.replace(~r/[^A-Za-z0-9\s]/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.slice(0, max_length)
  end
end
