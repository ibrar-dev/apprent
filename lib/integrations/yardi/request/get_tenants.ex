defmodule Yardi.Request.GetTenants do
  use Yardi.Request,
    container: "GetTenants",
    xmlns: "http://tempuri.org/YSI.Interfaces.WebServices/ItfCommonData",
    soap_action: "http://tempuri.org/YSI.Interfaces.WebServices/ItfCommonData/GetTenants",
    action: "itfcommondata.asmx"

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
      element("YardiPropertyId", options[:property_id])
    ]
  end
end
