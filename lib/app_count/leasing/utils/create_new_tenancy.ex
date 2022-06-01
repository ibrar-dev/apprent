defmodule AppCount.Leasing.Utils.CreateNewTenancy do
  alias AppCount.Core.ClientSchema

  @moduledoc """
    Lease creation. This module is for transfers and new tenant creation, renewals are handled elsewhere

    Params

    :tenant_id
    :unit_id (new unit id)
    :charges
    :date
    :start_date
    :end_date
  """
  alias Ecto.Multi
  alias AppCount.Leasing.Utils.CreateLease
  alias AppCount.Tenants.TenancyRepo
  alias AppCount.Ledgers.CustomerLedger
  alias AppCount.Properties.UnitRepo
  alias AppCount.Core.ClientSchema

  def create_new_tenancy(%ClientSchema{name: client_schema, attrs: params}) do
    params
    |> normalize_params()
    |> do_create_new_tenancy(client_schema)
  end

  def normalize_params(params) do
    Morphix.atomorphiform(params)
  end

  defp do_create_new_tenancy({:ok, params}, client_schema) do
    multi =
      Multi.new()
      |> create_and_merge_customer(ClientSchema.new(client_schema, params))

    ClientSchema.new(client_schema, multi)
    |> insert_new_tenancy(params)
    |> CreateLease.create_lease(&merge_customer_id/3, ClientSchema.new(client_schema, params))
  end

  defp do_create_new_tenancy(e, _client_schema), do: e

  defp create_and_merge_customer(multi, %ClientSchema{
         name: client_schema,
         attrs: %{unit_id: unit_id}
       }) do
    property_id = UnitRepo.get(unit_id, prefix: client_schema).property_id
    # TODO will replace this with new Finance.Customer stuff
    # also put the correct name in here
    customer_params = %{property_id: property_id, name: "Some Name", type: "tenant"}

    Multi.insert(
      multi,
      :customer_ledger,
      CustomerLedger.changeset(%CustomerLedger{}, customer_params)
    )
  end

  defp insert_new_tenancy(
         %ClientSchema{
           name: client_schema,
           attrs: multi
         },
         params
       ) do
    Multi.run(multi, :tenancy, fn _repo, cs ->
      params
      |> Map.put(:customer_ledger_id, cs.customer_ledger.id)
      |> TenancyRepo.insert(prefix: client_schema)
    end)
  end

  defp merge_customer_id(_repo, cs, %ClientSchema{
         name: client_schema,
         attrs: params
       }) do
    params
    |> Map.put(:customer_ledger_id, cs.customer_ledger.id)
    |> AppCount.Leasing.LeaseRepo.insert(prefix: client_schema)
  end
end
