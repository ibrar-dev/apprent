defmodule Yardi.Request.GetChartOfAccounts do
  use Yardi.Request,
    container: "ExportChartOfAccounts",
    xmlns: "http://tempuri.org/YSI.Interfaces.WebServices/ItfResidentTransactions20",
    soap_action:
      "http://tempuri.org/YSI.Interfaces.WebServices/ItfResidentTransactions20/ExportChartOfAccounts",
    action: "itfResidentTransactions20.asmx"

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
      element("PropertyId", options[:property_id])
    ]
  end
end
