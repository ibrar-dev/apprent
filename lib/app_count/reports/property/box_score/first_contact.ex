defmodule AppCount.Reports.Property.BoxScore.FirstContact do
  import Ecto.Query
  alias AppCount.Reports.Property.BoxScore.Applicants
  alias AppCount.Repo

  @doc """
  This function fixes the existing box_score reports by breaking down the fees in the
  description
  """
  def get_payments_with_description(property_id, start_date, end_date) do
    Applicants.get_payments(property_id, start_date, end_date)
    |> Enum.map(fn x -> get_receipts(x) end)
  end

  def add_new_description(new_description, application_info) do
    %{
      amount: application_info.amount,
      application_id: application_info.application_id,
      date: application_info.date,
      expected_move_in: application_info.expected_move_in,
      floor_plan: application_info.floor_plan,
      id: application_info.id,
      payer: application_info.payer,
      persons: application_info.persons,
      response: application_info.response,
      tenant_id: application_info.tenant_id,
      transaction_id: application_info.transaction_id,
      description: new_description
    }
  end

  def get_receipts(application_info) do
    Repo.all(
      from r in AppCount.Accounting.Receipt,
        where: r.payment_id == ^application_info.id,
        preload: [:account]
    )
    |> Enum.map(fn x -> process_receipts(x) end)
    |> add_new_description(application_info)
  end

  def process_receipts(receipt) do
    case receipt.account do
      nil ->
        "Unknown Payment"

      _ ->
        amount = receipt.amount
        fee_type = receipt.account.description

        "#{fee_type}: $#{amount}"
    end
  end
end
