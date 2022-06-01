defmodule Authorize.DeleteCustomer do
  import Authorize.Authentication
  import XmlBuilder
  import SweetXml
  alias Authorize.URL

  @headers [{"Content-Type", "text/xml"}]

  def request(processor, customer_info) do
    element(
      :deleteCustomerProfileRequest,
      %{xmlns: "AnetApi/xml/v1/schema/AnetApiSchema.xsd"},
      [
        auth_node(processor),
        element(:customerProfileId, customer_info.authorize_profile_id)
      ]
    )
  end

  def delete_profile(processor, customer_info) do
    req = request(processor, customer_info) |> generate()

    HTTPoison.post(URL.url(), req, @headers)
    |> process_response()
  end

  defp process_response({:ok, %HTTPoison.Response{body: body}}) do
    successful_result_code = xpath(body, ~x"//messages/resultCode/text()"S)
    error_code = xpath(body, ~x"//messages/message/code/text()"S)
    error_description = xpath(body, ~x"//messages/message/text/text()"S)

    if successful_result_code == "Ok" do
      {:ok, successful_result_code}
    else
      {:error, "Error: " <> error_code <> " " <> error_description}
    end
  end
end
