defmodule AppCount.Maintenance.InsightReportSubscriptions do
  alias AppCount.Maintenance.InsightReportSubscription
  alias AppCount.Maintenance.InsightReport
  alias AppCount.Repo

  import Ecto.Query

  @moduledoc """
  Let's work with our insight reports subscriptions.
  """

  @doc """
  Given an Admin ID, find all subscriptions for that admin
  """
  def index(admin_id) do
    Repo.all(
      from s in InsightReportSubscription,
        where: s.admin_id == ^admin_id
    )
  end

  @doc """
  Subscribed admins for a given report -- we use the report type and property ID
  to determine who should be receiving updates; returned as a list of IDs
  """
  def admin_ids_for(%InsightReport{type: type, property_id: property_id}) do
    Repo.all(
      from s in InsightReportSubscription,
        where: s.type == ^type and s.property_id == ^property_id,
        select: s.admin_id
    )
  end

  @doc """
  Look up a single report, either by ID or by unique combo of property id, admin
  id and type
  """
  def fetch(id) when is_integer(id) do
    Repo.one(
      from s in InsightReportSubscription,
        where: s.id == ^id,
        preload: [:property, :admin],
        limit: 1
    )
  end

  def fetch(%{admin_id: admin_id, property_id: property_id, type: type}) do
    Repo.one(
      from s in InsightReportSubscription,
        where: s.admin_id == ^admin_id and s.property_id == ^property_id and s.type == ^type,
        preload: [:property, :admin],
        limit: 1
    )
  end

  def destroy(id) do
    Repo.delete_all(
      from s in InsightReportSubscription,
        where: s.id == ^id
    )

    :ok
  end

  @doc """
  Given params, let's make a new report record please. Acts like a find-or-create-by.

  Returns {:ok, subscription} or {:error, reason}
  """
  def create(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: %{type: type, admin_id: admin_id, property_id: property_id}
      }) do
    candidate = fetch(%{type: type, admin_id: admin_id, property_id: property_id})

    if is_nil(candidate) do
      %InsightReportSubscription{}
      |> InsightReportSubscription.changeset(%{
        type: type,
        admin_id: admin_id,
        property_id: property_id
      })
      |> Repo.insert(prefix: client_schema)
    else
      {:ok, candidate}
    end
  end
end
