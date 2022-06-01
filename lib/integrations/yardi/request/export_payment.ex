defmodule Yardi.Request.ExportPayment do
  use Yardi.Request,
    container: "ImportResidentTransactions_Login",
    xmlns: "http://tempuri.org/YSI.Interfaces.WebServices/ItfResidentTransactions20",
    soap_action:
      "http://tempuri.org/YSI.Interfaces.WebServices/ItfResidentTransactions20/ImportResidentTransactions_Login",
    action: "itfresidenttransactions20.asmx"

  @required_options [
    :property_id,
    :credentials,
    :property_name,
    :transaction_id,
    :payment_id,
    :customer_id,
    :amount,
    :payment_date
  ]

  def request_body(options) do
    credentials = options[:credentials]

    [
      element("UserName", credentials.username),
      element("Password", credentials.password),
      element("ServerName", credentials.server_name),
      element("Database", credentials.db),
      element("Platform", credentials.platform),
      element("InterfaceEntity", credentials.entity),
      element("InterfaceLicense", credentials.interface),
      element("TransactionXml", [transaction_xml(options)])
    ]
  end

  def transaction_xml(options) do
    element(
      "ResidentTransactions",
      %{"xmlns:MITS" => "http://my-company.com/namespace"},
      [
        element(
          "Property",
          [
            element(
              "PropertyID",
              [
                element(
                  "MITS:Identification",
                  %{Type: "other"},
                  [
                    element("MITS:PrimaryID", options[:property_id]),
                    element("MITS:MarketingName", options[:property_name])
                  ]
                )
              ]
            ),
            element(
              "RT_Customer",
              [
                element("CustomerID", options[:customer_id]),
                element("PaymentAccepted", "1"),
                element(
                  "RTServiceTransactions",
                  [
                    element(
                      "Transactions",
                      [
                        element(
                          "Payment",
                          %{Type: payment_type(options[:source])},
                          [
                            element(
                              "Detail",
                              [
                                element("Description", description(options[:source])),
                                element("TransactionID", options[:transaction_id]),
                                element("DocumentNumber", document_number(options[:payment_id])),
                                element("TransactionDate", options[:payment_date]),
                                element("GLAccountNumber", options[:credentials].gl_account),
                                element("CustomerID", options[:customer_id]),
                                element(
                                  "Amount",
                                  :erlang.float_to_binary(options[:amount], decimals: 2)
                                ),
                                element("Comment", description(options[:source])),
                                element("PropertyPrimaryID", options[:property_id])
                              ]
                            )
                          ]
                        )
                      ]
                    )
                  ]
                )
              ]
            )
          ]
        )
      ]
    )
  end

  def validate_options!(options) do
    unless Enum.all?(@required_options, &options[&1]) do
      raise "Missing required values for Yardi payment import: #{inspect(options)}"
    end
  end

  defp document_number(unique_id) do
    UUID.uuid3(:dns, "administration.apprent-#{unique_id}.com")
    |> UUID.string_to_binary!()
    |> :erlang.binary_to_list()
    |> Enum.join("")
    |> String.split_at(10)
    |> elem(0)
  end

  defp payment_type("moneygram"),
    do: "Cash"

  defp payment_type(_),
    do: "Other"

  defp description("moneygram"), do: "AppRent MoneyGram Payment"

  defp description(_), do: "AppRent Payment"
end
