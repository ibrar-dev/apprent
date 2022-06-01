defmodule BlueMoon.Requests.CreateLease do
  alias BlueMoon.Utils
  import XmlBuilder

  defmodule Parameters do
    @enforce_keys [:property_id, :lease_params, :custom_params]
    defstruct property_id: nil, lease_params: nil, custom_params: nil
  end

  @spec request(%Parameters{}) :: list()
  def request(%Parameters{} = params) do
    body = [
      element(
        "LEASE",
        nil,
        [
          element("STANDARD", nil, Utils.params_to_xml(params.lease_params)),
          element("CUSTOM", nil, Utils.params_to_xml(params.custom_params))
        ]
      )
    ]

    [element("LeaseXMLData", nil, generate(body)), element("PropertyId", nil, params.property_id)]
  end
end
