defmodule BlueMoon.Requests.EditLease do
  alias BlueMoon.Utils
  import XmlBuilder

  defmodule Parameters do
    @enforce_keys [:lease_id, :lease_params, :custom_params]
    defstruct lease_id: nil, lease_params: nil, custom_params: nil
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

    [element("LeaseXMLData", nil, generate(body)), element("LeaseId", nil, params.lease_id)]
  end
end
