defmodule AppCount.Leasing.BlueMoon.Credentials do
  alias BlueMoon.Credentials
  alias AppCount.Properties.Processors
  alias AppCount.Core.ClientSchema

  def credentials_for_property(%ClientSchema{
        name: client_schema,
        attrs: property_id
      }) do
    case Processors.processor_credentials(
           %ClientSchema{
             name: client_schema,
             attrs: property_id
           },
           "lease"
         ) do
      nil -> raise "No processor found for this property"
      credentials -> struct(Credentials, credentials)
    end
  end
end
