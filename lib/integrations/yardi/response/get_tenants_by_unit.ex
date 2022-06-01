defmodule Yardi.Response.GetTenantsByUnit do
  def new({:ok, response}), do: new(response)

  def new(response) do
    response[:GetTenantsByUnitResult][:GetUnit][:Unit][:Residents][:Resident]
    |> extract_content
    |> List.wrap()
  end

  defp extract_content(residents) when is_list(residents) do
    Enum.map(residents, &extract_content/1)
  end

  defp extract_content(resident) do
    %{
      t_code: resident.attributes[:tCode],
      status: resident[:Status].content,
      first_name: resident[:FirstName].content,
      last_name: resident[:LastName].content,
      current_rent: resident[:CurrentRent].content
    }
  end
end
