defmodule Yardi.Response.GetTenants do
  def new({:ok, response}), do: new(response)

  def new(response) do
    if response[:GetTenantsResult][:Messages] do
      {:error, response[:GetTenantsResult][:Messages][:Message].content}
    else
      container = response[:GetTenantsResult][:CommonTenantsData][:PropertyTenants]

      if container.content do
        tenants = container[:Tenants][:Tenant]
        {:ok, Enum.map(tenants, &process_tenant/1)}
      else
        # Note: we are not currently sure what this kind of response means
        # and we aren't sure what to report, so for now just a roughly descriptive message
        {:error, "Empty tenants element"}
      end
    end
  end

  def process_tenant(tenant_element) do
    %{
      p_code: tenant_element.attributes.pCode,
      t_code: tenant_element.attributes.tCode,
      status: tenant_element[:Status].content,
      first_name: tenant_element[:FirstName].content,
      last_name: tenant_element[:LastName].content,
      phone: extract_phone(tenant_element),
      email: extract_optional(tenant_element, :Email),
      unit_code: tenant_element[:UnitCode].content,
      lease_from_date: convert_date_format(tenant_element[:LeaseFromDate].content),
      lease_to_date: convert_date_format(tenant_element[:LeaseToDate].content),
      move_in_date: convert_date_format(tenant_element[:MoveInDate].content),
      move_out_date: convert_date_format(tenant_element[:MoveOutDate].content),
      notice_date: convert_date_format(tenant_element[:NoticeDate].content)
    }
  end

  defp extract_phone(tenant_element) do
    case tenant_element[:Phone] do
      nil -> nil
      list when is_list(list) -> hd(list)[:PhoneNumber].content
      el -> el[:PhoneNumber].content
    end
  end

  defp extract_optional(element, key) do
    if element[key], do: element[key].content, else: nil
  end

  defp convert_date_format(nil), do: nil

  defp convert_date_format(date_string) do
    date_string
    |> Timex.parse!("{M}/{D}/{YYYY}")
    |> Timex.to_date()
  end
end
