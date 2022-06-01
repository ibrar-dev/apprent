defmodule Yardi.Gateway.GetImportResidentsCase do
  use AppCount.Case
  alias AppCount.Support.HTTPClient
  @moduletag :yardi_gateway_import_residents

  @import_residents File.read!(
                      Path.expand(
                        "../../resources/Yardi/import_residents.xml",
                        __DIR__
                      )
                    )

  test "import_residents" do
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

    HTTPClient.initialize([@import_residents])
    {:ok, result} = Yardi.Gateway.import_residents("1x1x", credentials)
    HTTPClient.stop()

    assert result == [
             %Yardi.Response.GetResidents.Tenant{
               actual_move_in_date: "2015-07-01",
               actual_move_out_date: "2021-06-01",
               current_rent: "900.00",
               email: "mrsballard1983@g8p3c.com",
               error: nil,
               expected_move_in_date: "2015-07-01",
               expected_move_out_date: nil,
               external_id: "t0019239",
               first_name: "Stephanie",
               last_name: "Ballard",
               lease_end: "2021-06-01",
               lease_start: "2020-06-01",
               phone: "2159545856",
               property_id: "4010",
               status: "current",
               unit_id: "207",
               payment_accepted: "2"
             },
             %Yardi.Response.GetResidents.Tenant{
               actual_move_in_date: "2019-03-25",
               actual_move_out_date: nil,
               current_rent: "489.00",
               email: "ziannafrazier@gmail.com",
               error: nil,
               expected_move_in_date: "2019-03-25",
               expected_move_out_date: "2021-03-25",
               external_id: "t0023580",
               first_name: "Lynnzianna",
               last_name: "Frazier",
               lease_end: "2021-03-24",
               lease_start: "2020-03-25",
               phone: "5207714513",
               property_id: "2010",
               status: "current",
               unit_id: "0925",
               payment_accepted: "0"
             },
             %Yardi.Response.GetResidents.Tenant{
               actual_move_in_date: "2019-07-26",
               actual_move_out_date: nil,
               current_rent: "787.00",
               email: "tisenedwin@icloud.com",
               error: nil,
               expected_move_in_date: "2019-07-26",
               expected_move_out_date: nil,
               external_id: "t0027163",
               first_name: "Tisen",
               last_name: "Edwin",
               lease_end: "2021-04-30",
               lease_start: "2020-05-01",
               phone: "5203696494",
               property_id: "2010",
               status: "current",
               unit_id: "0315",
               payment_accepted: "0"
             },
             %Yardi.Response.GetResidents.Tenant{
               actual_move_in_date: "2017-06-15",
               actual_move_out_date: nil,
               current_rent: "596.00",
               email: "2sl.moll@gmail.com",
               error: nil,
               expected_move_in_date: "2017-06-15",
               expected_move_out_date: nil,
               external_id: "t0005340",
               first_name: "Stacy",
               last_name: nil,
               lease_end: "2021-06-30",
               lease_start: "2020-07-01",
               phone: nil,
               property_id: "2010",
               status: "current",
               unit_id: "0313",
               payment_accepted: "0"
             }
           ]
  end
end
