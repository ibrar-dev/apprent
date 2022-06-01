defmodule Authorize.CreateTransaction do
  import Authorize.Authentication
  import XmlBuilder

  def request(amount, source, processor) do
    element(
      :createTransactionRequest,
      %{xmlns: "AnetApi/xml/v1/schema/AnetApiSchema.xsd"},
      [
        auth_node(processor),
        transaction(amount, source)
      ]
    )
  end

  # Charge a token - 1 time transaction
  defp transaction(amount, %{type: "cc", token_value: value, token_description: description}) do
    element(
      :transactionRequest,
      [
        element(:transactionType, "authCaptureTransaction"),
        element(:amount, amount),
        element(
          :payment,
          [
            element(
              :opaqueData,
              [
                element(dataDescriptor: description),
                element(dataValue: value)
              ]
            )
          ]
        )
      ]
    )
  end

  # Charge a stored customer profile
  defp transaction(
         amount,
         %{
           type: "cc",
           num1: customer_id,
           num2: payment_profile_id,
           is_tokenized: true
         } = source
       ) do
    element(
      :transactionRequest,
      [
        element(:transactionType, "authCaptureTransaction"),
        element(:amount, amount),
        element(
          :profile,
          [
            element(:customerProfileId, customer_id),
            element(
              :paymentProfile,
              [
                element(:paymentProfileId, payment_profile_id)
              ]
            )
          ]
        ),
        element(:processingOptions, [
          element(:isSubsequentAuth, "true"),
          element(:isStoredCredentials, "true")
        ]),
        element(:subsequentAuthInformation, [
          element(:originalNetworkTransId, original_network_transaction_id(source)),
          element(:originalAuthAmount, original_auth_amount(source)),
          element(:reason, "reauthorization")
        ])
      ]
    )
  end

  def original_network_transaction_id(source) do
    source.original_network_transaction_id || "0"
  end

  # Get from amount in cents to a string like "1.23"
  def original_auth_amount(source) do
    amount_in_cents = source.original_auth_amount_in_cents || 0

    AppCount.Finance.Money.amount_as_string(amount_in_cents)
  end
end
