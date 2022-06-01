defmodule AppCount.Units.Utils.DefaultLeaseCharges do
  import Ecto.Query
  alias AppCount.Units.DefaultLeaseCharge
  alias AppCount.Properties.Unit
  alias AppCount.Repo
  alias Ecto.Multi

  def create_default_charge(params) do
    %DefaultLeaseCharge{}
    |> DefaultLeaseCharge.changeset(params)
    |> Repo.insert()
  end

  defp create_line_default_charge(params, {:ok, charges}) do
    create_default_charge(params)
    |> case do
      {:ok, c} -> {:cont, {:ok, charges ++ [c]}}
      {:error, e} -> {:halt, {:error, e}}
    end
  end

  defp create_line_default_charge(_params, {:error, error}), do: {:halt, {:error, error}}

  def multi_create_default_charges(params) do
    Multi.new()
    |> Multi.run(:default_charges, fn _repo, _cs ->
      params
      |> Enum.reduce_while({:ok, []}, &create_line_default_charge(&1, &2))
    end)
    |> Repo.transaction()
  end

  def update_default_charges(params) do
    Multi.new()
    |> Multi.run(:default_charges, fn _, _ ->
      params
      |> Enum.reduce_while({:ok, []}, &update_line_default_charge(&1, &2))
    end)
    |> Repo.transaction()
  end

  defp update_line_default_charge(params, {:ok, charges}) do
    update_default_charge(params["id"], params)
    |> case do
      {:ok, c} -> {:cont, {:ok, charges ++ [c]}}
      {:error, e} -> {:halt, {:error, e}}
    end
  end

  defp update_line_default_charge(_params, {:error, error}), do: {:halt, {:error, error}}

  def update_default_charge(id, params) do
    charge = Repo.get(DefaultLeaseCharge, id)
    history = charge.history ++ [%{price: charge.price, time: AppCount.current_time()}]

    charge
    |> DefaultLeaseCharge.changeset(Map.merge(params, %{"history" => history}))
    |> Repo.update()
  end

  def delete_default_charge(id) do
    Repo.get(DefaultLeaseCharge, id)
    |> Repo.delete()
  end

  def clone_charges(initial_floor_plan_id, target_floor_plan_id) do
    from(
      c in DefaultLeaseCharge,
      where: c.floor_plan_id == ^initial_floor_plan_id,
      select: %{
        price: c.price,
        default_charge: c.default_charge,
        charge_code_id: c.charge_code_id
      }
    )
    |> Repo.all()
    |> Enum.each(fn c ->
      Map.merge(c, %{floor_plan_id: target_floor_plan_id})
      |> create_default_charge
    end)
  end

  def default_charges(unit_id) do
    from(
      u in Unit,
      join: fp in assoc(u, :floor_plan),
      join: c in assoc(fp, :default_charges),
      where: u.id == ^unit_id,
      select: c
    )
    |> Repo.all()
  end
end
