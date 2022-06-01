defmodule AppCount.Reports.Index do
  alias AppCount.Reports.Financial

  defp index(key) do
    %{
      balance: Financial.Balance.Report,
      income: Financial.Income.Report,
      t12: Financial.T12.Report,
      gl: Financial.GeneralLedger.Report,
      budget: Financial.Budget.Report
    }
    |> Map.fetch!(key)
  end

  def report_module(id) when is_binary(id), do: report_module(String.to_existing_atom(id))
  def report_module(id), do: index(id)
end
