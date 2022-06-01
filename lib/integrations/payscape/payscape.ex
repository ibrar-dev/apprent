defmodule Payscape do
  alias Payscape.CreateTransaction
  alias Payscape.Request
  import SweetXml

  @spec process_payment(float, map, map) :: {:ok, String.t()} | {:error, map}
  def process_payment(amount, source, processor) do
    req =
      CreateTransaction.request(amount, source, processor)
      |> XmlBuilder.generate()

    Request.request(req, processor)
    |> parse_response()
  end

  defp parse_response({:ok, body}) do
    parsed =
      body
      |> parse(namespace_conformant: true)
      |> xmap(
        transaction_id: ~x"//XMLResponse/XMLTrans/transNum/text()"S,
        status: ~x"//XMLResponse/XMLTrans/status/text()"S,
        invoice_number: ~x"//XMLResponse/XMLTrans/invNum/text()"S
      )

    # Status codes: https://www.propay.com/en-US/Documents/API-Docs/ProPay-API-Manual-Appendix
    if parsed.status == "00" do
      {:ok, parsed}
    else
      error_message = humanized_error_message(parsed.status)

      {:error,
       %{
         reason:
           "Error code #{parsed.status}: #{error_message}. Please contact support@apprent.com or your property manager if you need help or have questions."
       }}
    end
  end

  defp parse_response(e), do: e

  # All of these error messages can be found here:
  # https://www.propay.com/en-US/Documents/API-Docs/ProPay-API-Appendix-B-Responses
  defp humanized_error_message("23") do
    "Invalid account type - please select 'checking' or 'savings'"
  end

  defp humanized_error_message("46") do
    "Transaction declined. Please double-check your routing number"
  end

  defp humanized_error_message("47") do
    "Transaction declined. Please double-check your bank account number"
  end

  defp humanized_error_message(_code) do
    "System Error"
  end
end
