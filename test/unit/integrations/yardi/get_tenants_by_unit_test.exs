defmodule Yardi.Gateway.GetTenantsByUnitCase do
  use AppCount.Case
  alias AppCount.Support.HTTPClient
  @moduletag :yardi_gateway_get_tenants_by_unit

  @get_tenants_by_unit File.read!(
                         Path.expand(
                           "../../resources/Yardi/get_tenants_by_unit.xml",
                           __DIR__
                         )
                       )

  test "get_tenants_by_unit" do
    credentials = %{
      username: "",
      password: "",
      platform: "",
      server_name: "",
      db: "",
      url: "",
      entity: "",
      interface: "",
      gl_account: ""
    }

    HTTPClient.initialize([@get_tenants_by_unit])
    result = Yardi.Gateway.get_tenants_by_unit("1x1x", "203", credentials)
    HTTPClient.stop()

    assert result == [
             %{
               current_rent: "1089.00",
               first_name: "James Robert",
               last_name: "Clark*",
               status: "Current",
               t_code: "t0029810"
             },
             %{
               current_rent: "810.00",
               first_name: "Christopher",
               last_name: "Williams",
               status: "Moved Out",
               t_code: "t0019236"
             }
           ]
  end
end
