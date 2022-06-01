defmodule Yardi.Gateway do
  use AppCount.ExternalService, :xml_adapter

  def import_residents(property_id, credentials) do
    Yardi.Gateway.Service.call(
      Yardi.Request.GetResidents,
      property_id: property_id,
      credentials: credentials
    )
    |> decode_into(Yardi.Response.GetResidents)
  end

  def get_tenants(property_id, credentials) do
    Yardi.Gateway.Service.call(
      Yardi.Request.GetTenants,
      property_id: property_id,
      credentials: credentials
    )
    |> decode_into(Yardi.Response.GetTenants)
  end

  #  def get_resident_transactions(options) do
  #    Yardi.Gateway.Service.call(Yardi.Request.GetResidentTransactions, options)
  #    |> decode_into(Yardi.Response.GetResidentTransactions)
  #  end

  def get_unit_information(property_id, credentials) do
    Yardi.Gateway.Service.call(
      Yardi.Request.GetUnitInformation,
      property_id: property_id,
      credentials: credentials
    )
    |> decode_into(Yardi.Response.GetUnitInformation)
  end

  def get_resident_data(property_id, tenant_id, credentials) do
    Yardi.Gateway.Service.call(
      Yardi.Request.GetResidentData,
      property_id: property_id,
      tenant_code: tenant_id,
      credentials: credentials
    )
    |> decode_into(Yardi.Response.GetResidentData)
  end

  def get_resident_lease_charges(property_id, tenant_id, credentials) do
    Yardi.Gateway.Service.call(
      Yardi.Request.GetResidentData,
      property_id: property_id,
      tenant_code: tenant_id,
      credentials: credentials
    )
    |> decode_into(Yardi.Response.GetResidentLeaseCharges)
  end

  def export_payment(options) do
    Yardi.Request.ExportPayment.validate_options!(options)

    Yardi.Gateway.Service.call(Yardi.Request.ExportPayment, options)
    |> decode_into(Yardi.Response.ExportPayment)
  end

  def get_tenants_by_unit(property_id, unit_number, credentials) do
    Yardi.Gateway.Service.call(
      Yardi.Request.GetTenantsByUnit,
      property_id: property_id,
      unit_id: unit_number,
      credentials: credentials
    )
    |> decode_into(Yardi.Response.GetTenantsByUnit)
  end

  def get_rent_roll(property_id, credentials) do
    Yardi.Gateway.Service.call(
      Yardi.Request.GetRentRoll,
      property_id: property_id,
      credentials: credentials
    )
    |> decode_into(Yardi.Response.GetRentRoll)
  end

  def get_chart_of_accounts(property_id, credentials) do
    Yardi.Gateway.Service.call(
      Yardi.Request.GetChartOfAccounts,
      property_id: property_id,
      credentials: credentials
    )
    |> decode_into(Yardi.Response.GetChartOfAccounts)
  end

  # private sub-module
  #
  defmodule Service do
    use AppCount.ExternalService, :service

    def call(request_type, options) do
      external_call(fn ->
        case request_type.perform(options) do
          {:error, reason} -> {:retry, reason}
          {:ok, reply} -> {:ok, reply}
        end
      end)
    end
  end
end
