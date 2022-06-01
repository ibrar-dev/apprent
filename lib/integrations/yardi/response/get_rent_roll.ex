defmodule Yardi.Response.GetRentRoll do
  def new({:ok, response}), do: new(response)

  def new(response) do
    first_document = hd(response[:GetRentrollResult][:XmlDocument])

    case hd(first_document.content) do
      %{name: :Properties} = el ->
        el[:Property][:Units][:Unit]
        |> Enum.map(&extract_unit_data/1)

      %{name: :GetRentroll, content: error} ->
        {:error, error}
    end
  end

  def extract_unit_data(unit_data) do
    tenants =
      if unit_data[:Tenants].content,
        do: extract_tenant_data(unit_data[:Tenants][:Tenant]),
        else: []

    %{
      unit_number: unit_data[:UnitCode].content,
      unit_status: unit_data[:UnitEconomicStatusDescription].content,
      tenants: List.wrap(tenants)
    }
  end

  def extract_tenant_data(tenant_data) when is_list(tenant_data) do
    Enum.map(tenant_data, &extract_tenant_data/1)
  end

  def extract_tenant_data(tenant_data) do
    %{
      tenant_code: content(tenant_data[:TenantCode]),
      tenant_status: content(tenant_data[:TenantStatus]),
      first_name: content(tenant_data[:FirstName]),
      last_name: content(tenant_data[:LastName]),
      lease_from: convert_date_format(tenant_data[:LeaseFrom]),
      lease_to: convert_date_format(tenant_data[:LeaseTo])
    }
  end

  defp content(nil), do: nil
  defp content(element), do: element.content
  defp convert_date_format(nil), do: nil

  defp convert_date_format(date_element) do
    date_element.content
    |> Timex.parse!("{M}/{D}/{YYYY}")
    |> Timex.to_date()
  end
end
