defmodule AppCount.Prospects.Utils.TrafficSources do
  import Ecto.Query
  alias AppCount.Prospects.TrafficSource
  alias AppCount.Repo

  def list_traffic_sources() do
    from(
      t in TrafficSource,
      left_join: p in assoc(t, :prospects),
      select: map(t, [:id, :name, :type]),
      select_merge: %{
        num_prospects: count(p.id)
      },
      group_by: t.id,
      order_by: [
        asc: :name
      ]
    )
    |> Repo.all()
  end

  def create_traffic_source(params) do
    %TrafficSource{}
    |> TrafficSource.changeset(params)
    |> Repo.insert()
  end

  def update_traffic_source(id, params) do
    Repo.get(TrafficSource, id)
    |> TrafficSource.changeset(params)
    |> Repo.update()
  end

  def delete_traffic_source(id) do
    Repo.get(TrafficSource, id)
    |> Repo.delete()
  end
end
