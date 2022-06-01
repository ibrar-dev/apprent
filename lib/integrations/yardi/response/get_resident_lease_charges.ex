defmodule Yardi.Response.GetResidentLeaseCharges do
  require Logger
  def new({:ok, response}), do: new(response)

  def new(response) do
    wrapper = response[:GetResidentDataResult][:"MITS-ResidentData"][:LeaseFiles]

    if wrapper do
      charges =
        wrapper[:LeaseFile][:LeaseCharges][:LeaseCharge]
        |> process_charges()

      {:ok, charges}
    else
      {:error, "Yardi error"}
    end
  end

  defp process_charges(list) when is_list(list), do: Enum.map(list, &process_charge/1)
  defp process_charges(charge), do: [process_charge(charge)]

  defp process_charge(charge) do
    %{
      charge_code: charge[:ChargeCode].content,
      charge_code_description: charge[:ChargeCodeDescription].content,
      amount: charge[:Amount].content,
      start_date: extract_content(charge[:StartDate]),
      end_date: extract_content(charge[:EndDate])
    }
  end

  defp extract_content(nil), do: nil
  defp extract_content(el), do: el.content
end
