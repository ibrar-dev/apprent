defmodule Yardi.Response.GetChartOfAccounts do
  def new({:ok, response}), do: new(response)

  def new(response) do
    response[:ExportChartOfAccountsResult][:Accounts][:Account]
    |> Enum.map(&account/1)
  end

  defp account(account_node) do
    %{
      number: account_node[:Code].content,
      description: account_node[:Description].content
    }
  end
end
