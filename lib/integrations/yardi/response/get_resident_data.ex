defmodule Yardi.Response.GetResidentData do
  defmodule Payment do
    defstruct [:date, :amount, :notes, :transaction_id]

    def to_map(entry) do
      entry
      |> Map.from_struct()
      |> Map.put(:type, "payment")
    end
  end

  defmodule Charge do
    defstruct [:date, :amount, :notes, :description, :code, :transaction_id]

    def to_map(entry) do
      entry
      |> Map.from_struct()
      |> Map.put(:type, "charge")
    end
  end

  def new({:ok, response}), do: new(response)

  def new(response) do
    lease_file = response[:GetResidentDataResult][:"MITS-ResidentData"][:LeaseFiles][:LeaseFile]

    lease_file[:Ledger][:Transaction]
    |> filter_only_posted
    |> process_transactions
  end

  def filter_only_posted(transactions) when is_list(transactions),
    do: Enum.filter(transactions, &is_posted?/1)

  def filter_only_posted(transaction), do: transaction

  # THIS IS STUPID AND NOT MY FAULT. XML == :(
  def is_posted?(transaction) do
    transaction[:isPosted].content
    |> case do
      "true" -> true
      "false" -> false
    end
  end

  def process_transactions(transactions) when is_list(transactions),
    do: Enum.map(transactions, &process_transaction/1)

  def process_transactions(nil), do: []
  def process_transactions(transaction), do: [process_transaction(transaction)]

  def process_transaction(transaction) do
    type =
      transaction[:TransType].content
      |> String.downcase()

    apply(__MODULE__, :"process_#{type}", [transaction])
  end

  def process_payment(payment) do
    %Payment{
      date: payment[:TransDate].content,
      amount: payment[:ChargeAmount].content,
      notes: payment[:Notes].content,
      transaction_id: payment[:TransID].content
    }
  end

  def process_charge(charge) do
    %Charge{
      date: charge[:TransDate].content,
      amount: charge[:ChargeAmount].content,
      notes: charge[:Notes].content,
      description: charge[:Description].content,
      code: charge[:ChargeCode].content,
      transaction_id: charge[:TransID].content
    }
  end
end
