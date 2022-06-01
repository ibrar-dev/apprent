defmodule Yardi.Response.GetUnitInformation do
  alias AppCount.Xml.Element

  defmodule Unit do
    defstruct [
      :external_id,
      :number,
      :current_resident_code,
      :area,
      :address
    ]
  end

  def new({:ok, response}), do: new(response)

  def new(response) do
    response[:GetUnitInformation_LoginResult][:PhysicalProperty][:Property][:RT_Customer]
    |> List.wrap()
    |> List.flatten()
    |> Enum.reduce([], &unit/2)
  end

  def unit(%Element{name: :RT_Customer} = el, acc) do
    unit_element = el[:RT_Unit]

    unit_info = unit_element[:Unit][:"MITS:Information"]

    unit = %Unit{
      current_resident_code: extract(el, [:CustomerID]),
      external_id: extract(unit_element, [:UnitIDValue]),
      number: extract(unit_element, [:UnitID]),
      area: extract(unit_info, [:"MITS:MinSquareFeet"]),
      address: address(unit_info)
    }

    [unit | acc]
  end

  def address(%Element{} = el) do
    %{
      street: extract(el, [:"MITS:Address", :"MITS:Address1"]),
      city: extract(el, [:"MITS:Address", :"MITS:City"]),
      state: extract(el, [:"MITS:Address", :"MITS:State"]),
      zipcode: extract(el, [:"MITS:Address", :"MITS:PostalCode"])
    }
  end

  def extract(nil, _), do: nil
  def extract(element, []), do: element.content
  def extract(element, [next | path]), do: extract(element[next], path)
end
