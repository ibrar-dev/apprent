defmodule AppCount.Maintenance.AssignmentRepo do
  # ref: https://medium.com/flatiron-labs/how-to-compose-queries-in-ecto-b71311729dac
  import AppCount.EctoExtensions
  use AppCount.Core.GenericRepo, schema: AppCount.Maintenance.Assignment

  alias AppCount.Properties.Property
  alias AppCount.Core.DateTimeRange

  def get_property_assignments(%Property{id: property_id}, %DateTimeRange{} = date_range)
      when is_integer(property_id) do
    @schema
    |> with_property_id(property_id)
    |> completed_within_range_or_open(date_range)
    |> with_preload()
    |> Repo.all()
  end

  def get_callback_assignments(%Property{id: property_id}, %DateTimeRange{} = date_range)
      when is_integer(property_id) do
    @schema
    |> with_property_id(property_id)
    |> completed_within_range(date_range)
    |> with_callback()
    |> with_preload()
    |> Repo.all()
  end

  def get_callback_assignments(property_ids, %DateTimeRange{} = date_range)
      when is_list(property_ids) do
    @schema
    |> with_property_id(property_ids)
    |> completed_within_range(date_range)
    |> with_callback()
    |> with_preload()
    |> Repo.all()
  end

  def with_preload(query \\ @schema) do
    query
    |> preload([a], [:tech, order: [:unit]])
  end

  def open(query \\ @schema) do
    query
    |> where([a, o], is_nil(a.completed_at))
  end

  # We have to compose with `or` instead of `or_where` because of how operator
  # precedence works when evaluating multiple `where` statements (composed as
  # `and`).
  def completed_within_range_or_open(query \\ @schema, %DateTimeRange{from: from, to: to}) do
    query
    |> where([a, o], is_nil(a.completed_at) or between(a.completed_at, ^from, ^to))
  end

  def completed_within_range(query \\ @schema, %DateTimeRange{from: from, to: to}) do
    query
    |> where([a, o], between(a.completed_at, ^from, ^to))
  end

  def with_property_id(query \\ @schema, identifier)

  def with_property_id(query, property_id) when is_integer(property_id) do
    query
    |> join(:left, [a], o in AppCount.Maintenance.Order, on: a.order_id == o.id)
    |> where([a, o], o.property_id == ^property_id)
  end

  def with_property_id(query, property_ids) when is_list(property_ids) do
    query
    |> join(:left, [a], o in AppCount.Maintenance.Order, on: a.order_id == o.id)
    |> where([a, o], o.property_id in ^property_ids)
  end

  def with_callback(query \\ @schema) do
    where(query, status: "callback")
  end
end
