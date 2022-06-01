defmodule Authorize.DeleteCustomerPaymentProfile do
  import Authorize.Authentication
  import XmlBuilder

  def request(processor, customer_info) do
    element(
      :deleteCustomerPaymentProfileRequest,
      %{xmlns: "AnetApi/xml/v1/schema/AnetApiSchema.xsd"},
      [
        auth_node(processor),
        element(:customerProfileId, customer_info.authorize_profile_id),
        element(:customerPaymentProfileId, customer_info.authorize_payment_profile_id)
      ]
    )
  end
end
