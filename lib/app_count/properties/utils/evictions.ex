defmodule AppCount.Properties.Utils.Evictions do
  alias AppCount.Repo
  alias AppCount.Ledgers.Utils.Charges
  alias AppCount.Tenants.Utils.Tenants
  alias AppCount.Properties.Eviction
  alias AppCount.Properties.Occupancy
  import Ecto.Query
  alias AppCount.Core.ClientSchema

  def create_eviction(params) do
    %Eviction{}
    |> Eviction.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, e} ->
        create_eviction_charge(params)
        block_payments(params)
        {:ok, e}

      {:error, e} ->
        {:error, e}
    end
  end

  def update_eviction(id, params) do
    Repo.get(Eviction, id)
    |> Eviction.changeset(params)
    |> Repo.update()
  end

  def delete_eviction(id) do
    Repo.get(Eviction, id)
    |> Repo.delete()
  end

  defp create_eviction_charge(%{"charge_amount" => num} = params) when num > 0 do
    bill_date =
      params["file_date"]
      |> Date.from_iso8601!()

    # TODO:SCHEMA remove dasmen
    Charges.create_charge(
      ClientSchema.new("dasmen", %{
        amount: num,
        status: "manual",
        bill_date: bill_date,
        lease_id: params["lease_id"],
        account_id: AppCount.Accounting.SpecialAccounts.get_account(:eviction).id
      })
    )
  end

  defp create_eviction_charge(_), do: nil

  defp block_payments(%{"lease_id" => lease_id}) do
    from(o in Occupancy, where: o.lease_id == ^lease_id, select: o.tenant_id)
    |> Repo.all()
    |> Enum.each(&Tenants.update_tenant(&1, %{payment_status: "cash"}))
  end
end
