defmodule AppCount.Prospects.Utils.Closures do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Prospects.Showing
  alias AppCount.Prospects.Closure
  alias AppCount.Repo
  alias AppCount.Prospects

  def list_closures(property_id) do
    s_query =
      from(
        s in Showing,
        join: p in assoc(s, :prospect),
        where: s.property_id == ^property_id,
        select: %{
          id: s.id,
          name: p.name,
          date: s.date,
          start_time: s.start_time
        }
      )

    from(
      c in Closure,
      left_join: s in subquery(s_query),
      on:
        fragment(
          "? = ? AND ? BETWEEN ? AND ?",
          s.date,
          c.date,
          s.start_time,
          c.start_time,
          c.end_time
        ),
      where: c.property_id == ^property_id,
      select: map(c, [:id, :date, :start_time, :end_time, :reason, :admin, :property_id]),
      select_merge: %{
        showings: jsonize(s, [:id, :name, :date, :start_time])
      },
      order_by: [asc: :date],
      group_by: [c.id]
    )
    |> Repo.all()
  end

  def create_closure(params, :all) do
    from(
      p in AppCount.Properties.Property,
      select: p.id
    )
    |> Repo.all()
    |> Enum.each(&create_closure(Map.merge(params, %{"property_id" => &1})))
  end

  def create_closure(params) do
    %Closure{}
    |> Closure.changeset(params)
    |> Repo.insert()
    |> update_prospects
  end

  def update_closure(id, params) do
    Repo.get(Closure, id)
    |> Closure.changeset(params)
    |> Repo.update()
    |> update_prospects
  end

  def delete_closure(id) do
    Repo.get(Closure, id)
    |> Repo.delete()
  end

  defp update_prospects({:error, _} = e), do: e

  defp update_prospects({:ok, closure}) do
    prospects =
      from(
        s in Showing,
        join: p in assoc(s, :prospect),
        join: property in assoc(s, :property),
        left_join: logo in assoc(property, :logo_url),
        where:
          s.date == ^closure.date and
            fragment("? BETWEEN ? AND ?", s.start_time, ^closure.start_time, ^closure.end_time) and
            s.property_id == ^closure.property_id,
        select: %{
          id: s.id,
          start_time: s.start_time,
          date: s.date,
          name: p.name,
          email: p.email,
          reason: ^closure.reason,
          property: merge(property, %{logo: logo.url})
        }
      )
      |> Repo.all()

    case length(prospects) do
      0 -> {:ok, closure}
      _ -> notify_prospects(prospects, {:ok, closure})
    end
  end

  def notify_prospects(list, {:ok, closure}) do
    AppCount.Core.Tasker.start(fn ->
      list
      |> Enum.each(&update_and_mail(&1))
    end)

    {:ok, closure}
  end

  defp update_and_mail(p) do
    Prospects.update_showing(p.id, %{cancellation: AppCount.current_date()})

    case p.email do
      nil -> nil
      _ -> AppCountCom.Prospects.notify_of_closure(p)
    end
  end

  def list_affected_showings(property_id, date) do
    from(
      s in Showing,
      join: p in assoc(s, :prospect),
      where: s.property_id == ^property_id and s.date == ^date,
      select: %{
        id: s.id,
        name: p.name,
        start_time: s.start_time
      }
    )
    |> Repo.all()
  end
end
