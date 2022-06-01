defmodule AppCount.Reports.EffectiveRent do
  import Ecto.Query
  use AppCount.Decimal
  alias AppCount.Repo
  alias AppCount.Properties.Unit
  alias AppCount.Reports.Queries

  def run_report(property_id, date) do
    from(
      u in Unit,
      where: u.property_id == ^property_id,
      left_join: er in subquery(Queries.effective_rent(property_id, date)),
      on: er.unit_id == u.id,
      left_join: mr in subquery(Queries.market_rent(property_id, date)),
      on: mr.unit_id == u.id,
      select: %{
        id: u.id,
        number: u.number,
        sq_ft: u.area,
        market_rent: mr.market_rent,
        floor_plan: mr.floor_plan,
        effective_rent: er
      }
    )
    |> Repo.all()
    |> Enum.sort(&(&1.number < &2.number))
    |> Enum.map(&calculate_rents(&1))
  end

  defp calculate_rents(%{effective_rent: er} = data) when is_nil(er), do: data

  defp calculate_rents(%{effective_rent: er} = data) do
    potential_rent = calculate_potential(er)
    effective_rent = potential_rent - calculate_concession(er)
    lease_term = calculate_lease_term(er)

    Map.merge(data, %{
      months_effective_rent: effective_rent,
      months_potential_rent: potential_rent,
      lease_term: lease_term
    })
  end

  defp calculate_potential(%{months_charges: charges} = _er) do
    cond do
      is_nil(charges) -> 0
      true -> Enum.reduce(charges, 0, fn c, acc -> acc + c["amount"] end)
    end
  end

  defp calculate_concession(%{months_concessions: concessions} = _er) do
    cond do
      is_nil(concessions) -> 0
      true -> Enum.reduce(concessions, 0, fn c, acc -> acc + c["amount"] end)
    end
  end

  defp calculate_lease_term(%{start_date: start_d, end_date: end_d} = _er) do
    cond do
      is_nil(start_d) or is_nil(end_d) -> 0
      true -> Timex.diff(end_d, start_d, :months)
    end
  end

  # Effective Rent/Sq Ft is Total Lease Value / Lease Terms / Sq Ft.
end
