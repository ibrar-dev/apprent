# defmodule Yardi.Response.GetResidentTransactions do
#  alias AppCount.Xml.Element
#
#  defmodule Transaction do
#    defstruct [
#      :transaction_id,
#      :description,
#      :amount_paid,
#      :balance_due,
#      :amount,
#      :comment
#    ]
#  end
#
#  # THIS INTEGRATION IS NOT YET FINISHED OR IN USE
#
#  def new({:ok, response}), do: new(response)
#
#  def new(response) do
#    response[:GetResidentTransactions_LoginResult][:ResidentTransactions][:Property][:RT_Customer]
#    |> List.wrap()
#    |> List.flatten()
#    |> Enum.reduce([], &transactions/2)
#  end
#
#  def transactions(%Element{name: :RT_Customer} = el, acc) do
#    transactions =
#      el[:RTServiceTransactions][:Transactions]
#      |> Enum.reduce([], &extract_transaction/2)
#
#    [transactions | acc]
#  end
#
#  defp extract_transaction(%Element{name: :Transactions} = el, acc) do
#    extract_type(el[:Charge], acc)
#  end
#
#  defp extract_type(%Element{name: :Payment} = _el, acc), do: acc
#
#  defp extract_type(%Element{name: :Charge} = el, acc) do
#    charge_element = el[:Detail]
#
#    transaction = %Transaction{
#      transaction_id: extract(charge_element, [:TransactionID]),
#      description: extract(charge_element, [:Description]),
#      amount_paid: extract(charge_element, [:AmountPaid]),
#      balance_due: extract(charge_element, [:BalanceDue]),
#      amount: extract(charge_element, [:Amount]),
#      comment: extract(charge_element, [:Comment])
#    }
#
#    [transaction | acc]
#  end
#
#  def extract(nil, _), do: nil
#  def extract(element, []), do: element.content
#  def extract(element, [next | path]), do: extract(element[next], path)
# end
