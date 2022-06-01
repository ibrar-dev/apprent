defmodule Yardi.Gateway.GetRentRollCase do
  use AppCount.Case
  alias AppCount.Support.HTTPClient
  @moduletag :yardi_gateway_rent_roll

  @get_rent_roll File.read!(
                   Path.expand(
                     "../../resources/Yardi/rent_roll.xml",
                     __DIR__
                   )
                 )

  test "get_rent_roll" do
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

    HTTPClient.initialize([@get_rent_roll])
    result = Yardi.Gateway.get_rent_roll("1x1x", credentials)
    HTTPClient.stop()

    assert result == [
             %{
               tenants: [
                 %{
                   first_name: "Stacy",
                   last_name: "*Moll",
                   lease_from: ~D[2020-07-01],
                   lease_to: ~D[2021-06-30],
                   tenant_code: "t0005340",
                   tenant_status: "Current"
                 }
               ],
               unit_number: "0313",
               unit_status: "occupied"
             },
             %{
               tenants: [
                 %{
                   first_name: "Maricor",
                   last_name: "Nicholas",
                   lease_from: nil,
                   lease_to: nil,
                   tenant_code: "t0003570",
                   tenant_status: "Canceled"
                 },
                 %{
                   first_name: "Gene",
                   last_name: "Nesmith jr.",
                   lease_from: ~D[2019-07-05],
                   lease_to: ~D[2020-07-04],
                   tenant_code: "t0025055",
                   tenant_status: "Denied"
                 },
                 %{
                   first_name: "Thomas",
                   last_name: "Cistone",
                   lease_from: nil,
                   lease_to: nil,
                   tenant_code: "t0025278",
                   tenant_status: "Canceled"
                 },
                 %{
                   first_name: "Tisen",
                   last_name: "Edwin",
                   lease_from: ~D[2020-05-01],
                   lease_to: ~D[2021-04-30],
                   tenant_code: "t0027163",
                   tenant_status: "Current"
                 }
               ],
               unit_number: "0315",
               unit_status: "occupied"
             },
             %{
               tenants: [
                 %{
                   first_name: "Lynnzianna",
                   last_name: "Frazier",
                   lease_from: ~D[2020-03-25],
                   lease_to: ~D[2021-03-24],
                   tenant_code: "t0023580",
                   tenant_status: "Notice"
                 }
               ],
               unit_number: "0925",
               unit_status: "occupied"
             },
             %{
               tenants: [
                 %{
                   first_name: "Isabel",
                   last_name: "Valencia",
                   lease_from: nil,
                   lease_to: nil,
                   tenant_code: "t0018539",
                   tenant_status: "Canceled"
                 },
                 %{
                   first_name: "Kellie",
                   last_name: "Rynearson",
                   lease_from: ~D[2021-01-29],
                   lease_to: ~D[2022-01-28],
                   tenant_code: "t0045067",
                   tenant_status: "Future"
                 }
               ],
               unit_number: "0314",
               unit_status: "vacant"
             },
             %{tenants: [], unit_number: "WAIT21R", unit_status: "occupied"}
           ]
  end
end
