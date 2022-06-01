defmodule Yardi.Response.GetResidents do
  alias AppCount.Xml.Element

  defmodule Tenant do
    defstruct [
      :external_id,
      :email,
      :unit_id,
      :first_name,
      :last_name,
      :phone,
      :current_rent,
      :expected_move_in_date,
      :actual_move_in_date,
      :expected_move_out_date,
      :actual_move_out_date,
      :lease_start,
      :lease_end,
      :status,
      :error,
      :property_id,
      :payment_accepted
    ]
  end

  def new({:ok, response}) do
    if response[:GetResidentTransactions_LoginResult][:Messages] do
      {:error, response[:GetResidentTransactions_LoginResult][:Messages][:Message].content}
    else
      {:ok, new(response)}
    end
  end

  def new(response) do
    response[:GetResidentTransactions_LoginResult][:ResidentTransactions][:Property][:RT_Customer]
    |> List.wrap()
    |> List.flatten()
    |> Enum.reduce([], &tenant/2)
  end

  def tenant(%Element{name: :RT_Customer} = el, acc) do
    customer_element =
      el[:Customers][:"MITS:Customer"]
      |> extract_tenant

    tenant = %Tenant{
      external_id: extract(customer_element, [:"MITS:CustomerID"]),
      email: extract(customer_element, [:"MITS:Address", :"MITS:Email"]),
      unit_id: extract(customer_element, [:"MITS:Property", :"MITS:UnitID"]),
      first_name: extract(customer_element, [:"MITS:Name", :"MITS:FirstName"]),
      last_name: extract(customer_element, [:"MITS:Name", :"MITS:LastName"]),
      phone: extract(customer_element, [:"MITS:Phone", :"MITS:PhoneNumber"]),
      current_rent: extract(customer_element, [:"MITS:Lease", :"MITS:CurrentRent"]),
      expected_move_in_date:
        extract(customer_element, [:"MITS:Lease", :"MITS:ExpectedMoveInDate"]),
      actual_move_in_date: extract(customer_element, [:"MITS:Lease", :"MITS:ActualMoveIn"]),
      expected_move_out_date:
        extract(customer_element, [:"MITS:Lease", :"MITS:ExpectedMoveOutDate"]),
      actual_move_out_date: extract(customer_element, [:"MITS:Lease", :"MITS:ActualMoveOut"]),
      lease_start: extract(customer_element, [:"MITS:Lease", :"MITS:LeaseFromDate"]),
      lease_end: extract(customer_element, [:"MITS:Lease", :"MITS:LeaseToDate"]),
      property_id: extract(customer_element, [:"MITS:Property", :"MITS:PrimaryID"]),
      status: String.replace(customer_element.attributes[:Type], " resident", ""),
      payment_accepted: el[:PaymentAccepted].content
    }

    [tenant | acc]
  end

  def extract_tenant(list) when is_list(list),
    do: Enum.find(list, &(&1.attributes[:Type] != "customer"))

  def extract_tenant(content), do: content

  def extract(nil, _), do: nil
  def extract(element, []), do: element.content
  def extract(element, [next | path]), do: extract(element[next], path)
end
