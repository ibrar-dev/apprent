defmodule Authorize.CreateCustomer do
  import Authorize.Authentication
  alias Authorize.URL
  import XmlBuilder
  import SweetXml

  @headers [{"Content-Type", "text/xml"}]

  def create_profile(processor, source) do
    req =
      request(processor, source)
      |> generate()

    HTTPoison.post(URL.url(), req, @headers)
    |> process_response()
  end

  defp process_response({:ok, %HTTPoison.Response{body: body}}) do
    parse_response(body)
  end

  defp parse_response(body) do
    processed_result =
      xmap(body,
        result_code: ~x"//messages/resultCode/text()"S,
        code: ~x"//messages/message/code/text()"S,
        code_message: ~x"//messages/message/text/text()"S,
        authorize_profile_id: ~x"//createCustomerProfileResponse/customerProfileId/text()"S,
        authorize_payment_profile_id: ~x"//customerPaymentProfileIdList/numericString/text()"S,
        validation_direct_response_list:
          ~x"//createCustomerProfileResponse/validationDirectResponseList/string/text()"S
      )

    {initial_transaction_id, initial_amount} =
      parse_validation_response(processed_result.validation_direct_response_list)

    if processed_result.result_code == "Ok" do
      id_map = %{
        authorize_payment_profile_id: processed_result.authorize_payment_profile_id,
        authorize_profile_id: processed_result.authorize_profile_id,
        original_network_transaction_id: initial_transaction_id,
        original_auth_amount_in_cents: initial_amount
      }

      {:ok, id_map}
    else
      {:error, "Error: #{processed_result.code} #{processed_result.code_message}"}
    end
  end

  def request(processor, source) do
    element(
      :createCustomerProfileRequest,
      %{xmlns: "AnetApi/xml/v1/schema/AnetApiSchema.xsd"},
      [
        auth_node(processor),
        build(source),
        element(:validationMode, "testMode")
      ]
    )
  end

  # builds customer profile
  defp build(source) do
    element(
      :profile,
      [
        element(:description, Ecto.UUID.generate()),
        build_payment_profile(source)
      ]
    )
  end

  # token
  defp build_payment_profile(%{type: "cc", token_value: value, token_description: description}) do
    element(
      :paymentProfiles,
      [
        element(:customerType, "individual"),
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

  # These are from the (now deprecated) AIM Payment Gateway response strings,
  # yet Authorize still seems to expect that we use this format.
  #
  # https://www.authorize.net/content/dam/anet-redesign/documents/AIM_guide.pdf
  # (table 19)
  def parse_validation_response(response_string) do
    [
      _response_code,
      _response_subcode,
      _response_reason_code,
      _reason_response_text,
      _authorization_code,
      _avs_response,
      transaction_id,
      _invoice_number,
      _description,
      amount | _rest
    ] =
      response_string
      |> String.split(",")

    {amount_in_dollars, _} = Float.parse(amount)

    amount_in_cents =
      amount_in_dollars
      |> Kernel.*(100)
      |> trunc()

    {transaction_id, amount_in_cents}
  end
end
