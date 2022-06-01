defmodule AppCount.Support.Yardi.FakeGateway do
  @get_resident_data File.read!(
                       Path.expand("../../resources/Yardi/get_resident_data.xml", __DIR__)
                     )

  @export_payment_success File.read!(
                            Path.expand(
                              "../../resources/Yardi/export_payment_success.xml",
                              __DIR__
                            )
                          )
  @export_payment_failure File.read!(
                            Path.expand(
                              "../../resources/Yardi/export_payment_failure.xml",
                              __DIR__
                            )
                          )
  @get_rent_roll File.read!(
                   Path.expand(
                     "../../resources/Yardi/rent_roll.xml",
                     __DIR__
                   )
                 )

  @import_residents File.read!(
                      Path.expand(
                        "../../resources/Yardi/import_residents.xml",
                        __DIR__
                      )
                    )

  @get_tenants_by_unit File.read!(
                         Path.expand(
                           "../../resources/Yardi/get_tenants_by_unit.xml",
                           __DIR__
                         )
                       )
  @get_chart_of_accounts File.read!(
                           Path.expand(
                             "../../resources/Yardi/get_chart_of_accounts.xml",
                             __DIR__
                           )
                         )

  @get_tenants File.read!(
                 Path.expand(
                   "../../resources/Yardi/get_tenants.xml",
                   __DIR__
                 )
               )

  def get_resident_data(_property_id, _tenant_id, _credentials) do
    {:ok, %HTTPoison.Response{status_code: 200, body: @get_resident_data}}
    |> Yardi.Gateway.decode_into(Yardi.Response.GetResidentData)
  end

  def export_payment(options) do
    body =
      if options[:customer_id] == "failure",
        do: @export_payment_failure,
        else: @export_payment_success

    {:ok, %HTTPoison.Response{status_code: 200, body: body}}
    |> Yardi.Gateway.decode_into(Yardi.Response.ExportPayment)
  end

  def get_rent_roll(_external_id, _credentials) do
    {:ok, %HTTPoison.Response{status_code: 200, body: @get_rent_roll}}
    |> Yardi.Gateway.decode_into(Yardi.Response.GetRentRoll)
  end

  def import_residents(_external_id, _credentials) do
    {:ok, %HTTPoison.Response{status_code: 200, body: @import_residents}}
    |> Yardi.Gateway.decode_into(Yardi.Response.GetResidents)
  end

  def get_tenants_by_unit(_property_id, _unit_number, _credentials) do
    {:ok, %HTTPoison.Response{status_code: 200, body: @get_tenants_by_unit}}
    |> Yardi.Gateway.decode_into(Yardi.Response.GetTenantsByUnit)
  end

  def get_chart_of_accounts(_property_id, _credentials) do
    {:ok, %HTTPoison.Response{status_code: 200, body: @get_chart_of_accounts}}
    |> Yardi.Gateway.decode_into(Yardi.Response.GetChartOfAccounts)
  end

  def get_resident_lease_charges(_property_id, _tenant_id, _credentials) do
    {:ok, %HTTPoison.Response{status_code: 200, body: @get_resident_data}}
    |> Yardi.Gateway.decode_into(Yardi.Response.GetResidentLeaseCharges)
  end

  def get_tenants(_property_id, _credentials) do
    {:ok, %HTTPoison.Response{status_code: 200, body: @get_tenants}}
    |> Yardi.Gateway.decode_into(Yardi.Response.GetTenants)
  end
end
