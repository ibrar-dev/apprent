defmodule AppCount.Leasing.Utils.CreateLease do
  @moduledoc """
    General Lease creation. Used by AppCount.Leasing.Utils.CreateRenewal
    and AppCount.Leasing.Utils.CreateNewTenancy, NOT expected to be called directly by anything else.
  """
  alias Ecto.Multi
  alias AppCount.Leasing.LeaseRepo
  alias AppCount.Leasing.ChargeRepo
  alias AppCount.Core.ClientSchema

  def create_lease(
        multi \\ Multi.new(),
        lease_insert_fn \\ &default_lease_insert/3,
        %ClientSchema{
          name: client_schema,
          attrs: params
        }
      ) do
    multi
    |> Multi.run(
      :lease,
      &lease_insert_fn.(&1, &2, %ClientSchema{
        name: client_schema,
        attrs: params
      })
    )
    |> Multi.run(
      :charges,
      fn _repo, %{lease: l} ->
        Enum.reduce_while(
          Map.get(params, :charges, []),
          {:ok, []},
          fn c, {_, charges} ->
            Map.put(c, :lease_id, l.id)
            |> ChargeRepo.insert(prefix: client_schema)
            |> case do
              {:ok, c} -> {:cont, {:ok, [c | charges]}}
              e -> {:halt, e}
            end
          end
        )
      end
    )
    |> AppCount.Repo.transaction()
  end

  def default_lease_insert(_repo, _cs, %ClientSchema{
        name: client_schema,
        attrs: lease_params
      }),
      do: LeaseRepo.insert(lease_params, prefix: client_schema)
end
