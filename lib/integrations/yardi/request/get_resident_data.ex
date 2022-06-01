defmodule Yardi.Request.GetResidentData do
  use Yardi.Request,
    container: "GetResidentData",
    xmlns: "http://tempuri.org/YSI.Interfaces.WebServices/ItfResidentData",
    soap_action: "http://tempuri.org/YSI.Interfaces.WebServices/ItfResidentData/GetResidentData",
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
      element("TenantCode", options[:tenant_code]),
      element("IncludeLedger", true),
      element("IncludeLeaseCharges", true),
      element("IncludeVehicleInfo", false),
      element("IncludeRoommateData", false),
      element("IncludeEmployerData", false)
    ]
  end
end
