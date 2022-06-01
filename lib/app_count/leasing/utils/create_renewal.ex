defmodule AppCount.Leasing.Utils.CreateRenewal do
  @moduledoc """
    Lease creation. This module is for renewals only, new tenant creation and transfers are handled elsewhere

    Params

    :lease_id (lease that we are renewing)
    :charges
    :date
    :start_date
    :end_date
  """
  alias AppCount.Leasing.Utils.CreateLease
  alias AppCount.Leasing.LeaseRepo
  alias AppCount.Core.ClientSchema

  def create_renewal(%ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    params
    |> normalize_params()
    |> merge_unit_and_customer_ids(ClientSchema.new(client_schema))
    |> CreateLease.create_lease()
  end

  def normalize_params(params) do
    Morphix.atomorphiform(params)
  end

  defp merge_unit_and_customer_ids({:ok, %{lease_id: lease_id} = params}, %ClientSchema{
         name: client_schema
       }) do
    lease =
      LeaseRepo.get(lease_id, prefix: client_schema)
      |> Map.take([:customer_ledger_id, :unit_id])
      |> Map.merge(params)
      |> Map.delete(:lease_id)

    %ClientSchema{
      name: client_schema,
      attrs: lease
    }
  end

  defp merge_unit_and_customer_ids(e, _), do: e
end
