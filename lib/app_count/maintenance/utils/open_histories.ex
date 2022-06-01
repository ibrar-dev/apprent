defmodule AppCount.Maintenance.Utils.OpenHistories do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Maintenance.OpenHistory
  alias AppCount.Admins
  alias AppCount.Repo
  alias AppCount.Core.ClientSchema
  require Logger

  def list_open_histories(admin, date) do
    start_date = Timex.beginning_of_day(date)
    end_date = Timex.end_of_day(date)
    list_open_histories(admin, start_date, end_date)
  end

  def list_open_histories(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        start_date,
        end_date
      ) do
    start_date = Timex.beginning_of_day(start_date)
    end_date = Timex.end_of_day(end_date)
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    from(
      o in OpenHistory,
      join: p in assoc(o, :property),
      where: o.property_id in ^property_ids and between(o.inserted_at, ^start_date, ^end_date),
      select: %{
        id: o.id,
        open: o.open,
        date: o.inserted_at,
        property: %{
          id: p.id,
          name: p.name
        }
      },
      order_by: :inserted_at
    )
    |> Repo.all(prefix: client_schema)
  end

  def list_property_open(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: property_id
        },
        date
      ) do
    start_date = Timex.beginning_of_day(date)
    end_date = Timex.end_of_day(date)

    from(
      o in OpenHistory,
      where: between(o.inserted_at, ^start_date, ^end_date) and o.property_id == ^property_id,
      select: o.open,
      limit: 1
    )
    |> Repo.one(prefix: client_schema)
  end
end
