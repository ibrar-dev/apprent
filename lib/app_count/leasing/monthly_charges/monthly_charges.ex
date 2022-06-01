defmodule AppCount.Leasing.MonthlyCharges do
  alias AppCount.Leasing.MonthlyCharges.Data
  alias AppCount.Leasing.MonthlyCharges.Compute
  alias AppCount.Core.ClientSchema

  def perform(%ClientSchema{name: client_schema, attrs: nil}) when is_binary(client_schema) do
    current_date = AppCount.current_date()
    perform(%ClientSchema{name: client_schema, attrs: current_date})
  end

  def perform(%ClientSchema{name: client_schema, attrs: current_date}) do
    current_month_start =
      current_date
      |> Timex.beginning_of_month()

    Data.get_data(
      %ClientSchema{name: client_schema, attrs: current_date},
      current_month_start
    )
    |> Enum.map(&Compute.bill_tenant(&1, current_month_start))
    |> List.flatten()
  end
end
