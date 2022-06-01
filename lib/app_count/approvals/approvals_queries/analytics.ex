defmodule AppCount.Approvals.Utils.ApprovalsQueries.Analytics do
  import Ecto.Query
  alias AppCount.Approvals.Utils.ApprovalsQueries.AnalyticsFunctions
  alias AppCount.Repo

  # CHARTS FUNCTIONS
  def get_chart(property_ids, dates) do
    unit_counts = get_properties_unit_counts(property_ids)

    AnalyticsFunctions.costs_query(property_ids, dates)
    |> AppCount.Repo.all()
    |> Enum.map(&Map.merge(&1, %{status: get_status(&1), payee: get_payee_name(&1.params)}))
    |> Enum.map(fn a ->
      %{
        id: a.id,
        status: a.status,
        params: a.params,
        inserted_at: a.inserted_at,
        payee: a.payee,
        property_units: unit_counts[a.property_id],
        property_id: a.property_id,
        costs:
          Enum.map(
            a.approval_costs,
            &%{
              id: &1.id,
              amount: &1.amount,
              category_id: &1.category_id,
              category: &1.category.name
            }
          )
        # amount: Enum.reduce(a.approval_costs, Decimal.new(0), fn(c, acc) -> Decimal.add(c.amount, acc) end)
      }
    end)
  end

  def get_analytics(property_ids, "pending_approval"),
    do: AnalyticsFunctions.pending_approval(property_ids)

  def get_analytics(property_ids, "approved"),
    do: AnalyticsFunctions.approved(property_ids)

  def get_analytics(property_ids, "denied"),
    do: AnalyticsFunctions.denied(property_ids)

  def get_analytics(property_ids, "most_expensed_category"),
    do: AnalyticsFunctions.most_expensed_category(property_ids)

  def get_analytics(property_ids, "most_expensed_payee"),
    do: AnalyticsFunctions.most_expensed_payee(property_ids)

  def get_analytics(property_ids, "approved_per_unit"),
    do: AnalyticsFunctions.approved_per_unit(property_ids)

  defp get_status(%{approval_logs: logs, params: params} = approval) do
    cond do
      not is_nil(params["invoice_date"]) ->
        "approved"

      Enum.any?(
        filtered_and_sorted_logs(logs),
        &(&1.status in ["Declined", "Cancelled", "Denied"])
      ) ->
        "declined"

      AnalyticsFunctions.is_pending(approval) ->
        "pending"

      true ->
        "approved"
    end
  end

  defp filtered_and_sorted_logs(logs) do
    logs
    |> Enum.filter(&(!&1.deleted))
    |> Enum.sort_by(& &1.id, :desc)
  end

  defp get_payee_name(%{"payee_id" => payee_id}) do
    from(
      p in AppCount.Accounting.Payee,
      where: p.id == ^payee_id,
      select: p.name
    )
    |> Repo.one()
  end

  def get_properties_unit_counts(property_ids) do
    property_ids
    |> Enum.into(%{}, fn id -> {id, get_units_count(id)} end)
  end

  defp get_units_count(property_id) do
    from(
      p in AppCount.Properties.Property,
      where: p.id == ^property_id,
      join: u in assoc(p, :units),
      select: count(u.id)
    )
    |> Repo.one()
  end
end
