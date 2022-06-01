defmodule MoneyGram do
  import SweetXml
  import XmlBuilder

  def process_request(request_xml) do
    cond do
      String.match?(request_xml, ~r"real:loadRequest") -> load_request(request_xml)
      String.match?(request_xml, ~r"real:validationRequest") -> validation_request(request_xml)
      true -> {:error, :bad_request}
    end
  end

  def validation_request(request_xml) do
    %{account_number: num} =
      request_xml
      |> parse(namespace_conformant: true)
      |> xmap(account_number: ~x"//real:receiveAccountNumber/text()"S)

    {:ok, num}
  end

  def validation_response(params) do
    response("validationResponse", params)
  end

  def load_request(request_xml) do
    parsed =
      request_xml
      |> parse(namespace_conformant: true)
      |> xmap(
        account_number: ~x"//real:receiveAccountNumber/text()"S,
        amount: ~x"//real:receiveAmount/text()"F,
        ref_number: ~x"//real:referenceNumber/text()"S
      )

    {:ok, parsed}
  end

  def load_response(params) do
    response("loadResponse", params)
  end

  defp response(type, params) do
    element(
      "soapenv:Envelope",
      %{
        "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
        "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
      },
      [
        element(
          "soapenv:Body",
          [
            element(
              type,
              %{"xmlns" => "http://www.moneygram.com/RealTimeEP"},
              response_body(params)
            )
          ]
        )
      ]
    )
    |> generate(format: :none)
  end

  @field_dictionary %{
    status: "valid",
    message: "message",
    transaction_id: "partnerTransactionID",
    error_code: "mgiErrorCode",
    bpg_error_code: "bpgErrorCode"
  }

  defp response_body(params) when is_list(params) do
    params
    |> Enum.map(fn {k, v} ->
      element(@field_dictionary[k], v)
    end)
  end
end
