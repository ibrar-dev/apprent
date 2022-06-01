defmodule AppCount.Yardi.ImportAccounts do
  require Logger
  alias AppCount.Repo
  alias AppCount.Properties.Property
  alias AppCount.Properties.Processors
  alias AppCount.Accounting.Account
  alias AppCount.Core.ClientSchema

  def perform(property, gateway \\ Yardi.Gateway)

  def perform(%Property{id: property_id, external_id: property_external_id}, gateway)
      when is_binary(property_external_id) do
    credentials =
      Processors.processor_credentials(ClientSchema.new("dasmen", property_id), "management")

    if credentials do
      gateway.get_chart_of_accounts(property_external_id, credentials)
      |> Enum.each(&import_account/1)
    else
      {:error, "Missing property integration"}
    end
  end

  def perform(%Property{} = property, _),
    do: raise("No external ID found for property #{property.name}")

  def perform(property_id, gateway) do
    Repo.get(Property, property_id)
    |> perform(gateway)
  end

  defp import_account(%{description: name, number: num}) do
    %Account{}
    |> Account.changeset(%{name: name, num: num})
    |> Repo.insert(on_conflict: {:replace_all_except, [:id]}, conflict_target: [:num])
  end
end
