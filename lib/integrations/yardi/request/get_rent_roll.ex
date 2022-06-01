defmodule Yardi.Request.GetRentRoll do
  use Yardi.Request,
    container: "GetRentroll",
    xmlns: "http://tempuri.org/YSI.Interfaces.WebServices/ItfResidentData",
    soap_action: "http://tempuri.org/YSI.Interfaces.WebServices/ItfResidentData/GetRentroll",
    action: "ItfResidentData.asmx"

  def request_body(options) do
    credentials = options[:credentials]

    [
      element("UserName", credentials.username),
      element("Password", credentials.password),
      element("ServerName", credentials.server_name),
      element("Database", credentials.db),
      element("Platform", credentials.platform),
      element("InterfaceEntity", credentials.entity),
      element("InterfaceLicense", credentials.interface),
      element("YardiPropertyId", options[:property_id]),
      element("MoveIn", "#{distant_past()}"),
      element("MoveOut", "#{distant_past()}"),
      element("LeaseChgFrom", "#{distant_past()}"),
      element("LeaseChgTo", "#{distant_past()}")
    ]
  end

  def distant_past() do
    AppCount.current_date() |> Timex.shift(years: -40)
  end
end
