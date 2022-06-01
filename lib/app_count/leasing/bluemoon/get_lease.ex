defmodule AppCount.Leasing.BlueMoon.GetLease do
  alias AppCount.Core.ClientSchema

  def get_lease(
        %ClientSchema{
          name: client_schema,
          attrs: property_id
        },
        bluemoon_lease_id,
        bluemoon_gateway \\ BlueMoon
      ) do
    BlueMoon.Credentials
    |> struct(
      AppCount.Properties.Processors.processor_credentials(
        %ClientSchema{
          name: client_schema,
          attrs: property_id
        },
        "lease"
      )
    )
    |> bluemoon_gateway.get_lease_data(bluemoon_lease_id)
    |> handle_response
  end

  def handle_response({:ok, xml}), do: BlueMoon.Data.Params.to_params(xml)
  def handle_response(_), do: nil
end
