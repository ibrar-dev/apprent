defmodule AppCount.Properties.PropertyRepo do
  @moduledoc """
  This is not a good example of a Repo.
  The function in this Repo have business logic in them and that's not great.
  Instead, a Repo should just be concernd with getting fully formed structs into and out of the DB.
  Picking particular fields and special select logic makes a Repo messy.
  Look at the other Repos for better examples of what a Repo should do.
  """
  use AppCount.Core.GenericRepo,
    schema: AppCount.Properties.Property,
    preloads: [
      units: [],
      phone_numbers: []
    ]

  import Ecto.Query
  import AppCount.EctoExtensions

  alias AppCount.Core.DateTimeRange
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Order
  alias AppCount.Properties.Setting
  alias AppCount.Properties.Unit
  alias AppCount.Properties.Processor
  alias AppCount.Core.PropertyTopic
  alias AppCount.Maintenance.Job
  alias AppCount.Maintenance.Tech
  alias AppCount.Core.ClientSchema
  # For any property email we need: [logo, website, phone, lat, lng, social, name, icon]
  def info_for_email(property_id) do
    from(
      p in @schema,
      left_join: l in assoc(p, :logo_url),
      left_join: i in assoc(p, :icon_url),
      where: p.id == ^property_id,
      select:
        map(
          p,
          [
            :id,
            :name,
            :social,
            :lat,
            :lng,
            :phone,
            :website
          ]
        ),
      select_merge: %{
        logo: l.url,
        icon: i.url
      }
    )
    |> Repo.one()
  end

  def create_property(%ClientSchema{name: client_schema, attrs: params})
      when is_map(params) do
    {:ok, property} = insert(params, prefix: client_schema)
    {:ok, _, property} = AppCount.Public.Utils.Properties.sync_public(property)
    property_settings(ClientSchema.new(client_schema, property))

    PropertyTopic.property_created(%{property_id: property.id}, __MODULE__)
    {:ok, property}
  end

  def credit_card_payment_processor(property_id) when is_integer(property_id) do
    payment_processor(property_id, "cc")
  end

  def credit_card_payment_processor(_) do
    {:error, "Processor not found for property - invalid ID"}
  end

  def bank_account_payment_processor(property_id) when is_integer(property_id) do
    payment_processor(property_id, "ba")
  end

  def bank_account_payment_processor(_) do
    {:error, "Processor not found for property - invalid ID"}
  end

  defp payment_processor(property_id, type) do
    from(
      processor in Processor,
      where: processor.property_id == ^property_id,
      where: processor.type == ^type
    )
    |> Repo.one()
    |> case do
      %Processor{} = processor -> {:ok, processor}
      _ -> {:error, "Processor #{type} not found for property #{inspect(property_id)}"}
    end
  end

  def setting(property_id) when is_integer(property_id) do
    property =
      get(property_id)
      |> Repo.preload(:setting)

    property.setting
  end

  def active_property_ids(%AppCount.Core.ClientSchema{name: client_schema, attrs: _}) do
    @schema
    |> Repo.all(prefix: client_schema)
    |> Repo.preload(:setting)
    |> Enum.filter(fn property -> property.setting && property.setting.active end)
    |> Enum.map(fn %{id: id} -> id end)
  end

  def property_ids(%AppCount.Core.ClientSchema{name: client_schema, attrs: _}) do
    @schema
    |> Repo.all(prefix: client_schema)
    |> Enum.map(fn %{id: id} -> id end)
  end

  def with_property_code(query \\ @schema, property_code) do
    where(query, code: ^property_code)
  end

  def get_by_property_code(property_code) do
    @schema
    |> with_property_code(property_code)
    |> one()
  end

  def preload(%Property{} = property) do
    Repo.preload(property, @preloads)
  end

  def get_active_techs(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: %Property{id: property_id}
      }) do
    from(
      j in Job,
      where: j.property_id == ^property_id,
      preload: [:tech]
    )
    |> Repo.all(prefix: client_schema)
    |> Enum.map(fn %Job{tech: tech} -> tech end)
    |> Enum.uniq()
    |> Enum.filter(fn %Tech{} = tech -> tech.active end)
  end

  def unit_lease_status(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: property},
        date_range
      ) do
    AppCount.Reports.Queries.UnitStatus.full_unit_status(
      property.id,
      date_range.to
      |> DateTime.to_date()
    )
    |> Repo.all(prefix: client_schema)
  end

  # generalize
  def completion_time(%Property{id: property_id}, %DateTimeRange{from: from, to: to})
      when is_integer(property_id) do
    from(
      a in Assignment,
      join: o in assoc(a, :order),
      where:
        not is_nil(a.completed_at) and o.property_id == ^property_id and
          between(a.completed_at, ^from, ^to),
      select:
        fragment(
          "avg(EXTRACT(EPOCH FROM ?) - EXTRACT(EPOCH FROM ?))",
          a.completed_at,
          o.inserted_at
        )
    )
    |> Repo.one()
  end

  def units(%AppCount.Core.ClientSchema{name: client_schema, attrs: property_id}) do
    from(
      unit in Unit,
      where: unit.property_id == ^property_id
    )
    |> Repo.all(prefix: client_schema)
  end

  def completed_orders(%Property{id: property_id}, %DateTimeRange{from: from, to: to})
      when is_integer(property_id) do
    from(
      a in Assignment,
      join: o in assoc(a, :order),
      where:
        not is_nil(a.completed_at) and o.property_id == ^property_id and
          between(a.completed_at, ^from, ^to),
      select: count(a.id)
    )
    |> Repo.one()
  end

  def open_vendor_orders(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: %Property{id: property_id}
      }) do
    from(
      o in AppCount.Vendors.Order,
      join: u in assoc(o, :unit),
      join: p in assoc(u, :property),
      where: p.id == ^property_id and o.status != "Completed"
    )
    |> Repo.all(prefix: client_schema)
  end

  def open_maintenance_orders(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: %Property{id: property_id}
      }) do
    june_first_2020 = AppCount.june_first_2020()

    from(
      o in AppCount.Maintenance.Order,
      join: c in assoc(o, :category),
      join: pc in assoc(c, :parent),
      where: o.status in ["unassigned", "assigned"] and o.property_id == ^property_id,
      where: o.inserted_at >= ^june_first_2020,
      where: pc.name != "Make Ready"
    )
    |> Repo.all(prefix: client_schema)
  end

  def get_average_maintenance_rating(property, %DateTimeRange{from: from, to: to}) do
    # This subquery fetches only the highest "completed_at" value, as an order
    # may have many assignments and might possibly have more than 1 completed-at
    # value.
    assignment_subquery =
      from(
        a in Assignment,
        group_by: a.order_id,
        select: %{
          order_id: a.order_id,
          completed_at: max(a.completed_at),
          rating: max(a.rating)
        }
      )

    # Get our average work orders ratings -- these are ones performed by on-site
    # technicians
    Repo.one(
      from(
        o in Order,
        join: a in subquery(assignment_subquery),
        on: a.order_id == o.id,
        where:
          o.property_id == ^property.id and
            a.completed_at >= ^from and
            a.completed_at <= ^to,
        select: type(avg(a.rating), :float)
      )
    )
  end

  # used in WorkOrdersSubmittedProbe
  def get_submitted_work_orders(property, %DateTimeRange{from: from, to: to}) do
    # Get our work orders -- these are ones performed by on-site technicians
    submitted_work_order_count =
      Repo.one(
        from(
          o in Order,
          where:
            o.property_id == ^property.id and
              o.inserted_at >= ^from and
              o.inserted_at <= ^to,
          select: count(o.id)
        )
      )

    # Vendor orders must also be counted here -- we query for and count them
    # differently, much to everyone's dismay
    vendor_order_count =
      Repo.one(
        from(
          v in AppCount.Vendors.Order,
          where:
            v.property_id == ^property.id and
              v.inserted_at >= ^from and
              v.inserted_at <= ^to,
          select: count(v.id)
        )
      )

    # Wrap it up and put a bow on it
    submitted_work_order_count + vendor_order_count
  end

  # We define the start of our Make Ready cards with the move out date (returned as a Date)
  # and the end of our Make Ready cards with the completion date (returned as a ISO 8601 string)
  # this function will get any cards with a date after our start_date
  def completed_cards(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: %Property{} = property},
        %DateTimeRange{from: from}
      ) do
    thirty_days_ago_range = DateTimeRange.last30days(from)

    thirty_days_ago_on =
      thirty_days_ago_range.from
      |> DateTime.to_date()

    completed_cards(ClientSchema.new(client_schema, property), thirty_days_ago_on)
  end

  # def completed_cards(
  #   %AppCount.Core.ClientSchema{
  #     name: client_schema,
  #     attrs: Property{} = property}
  #     ,
  #   %Date{} = thirty_days_ago_on
  # ) do

  # def completed_cards(%Property{} = property, %Date{} = thirty_days_ago_on) do
  def completed_cards(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: %Property{} = property},
        %Date{} = thirty_days_ago_on
      ) do
    alias AppCount.Maintenance.Card

    from(
      c in Card,
      join: u in assoc(c, :unit),
      on: u.property_id == ^property.id,
      where:
        not is_nil(c.completion) and not is_nil(fragment("completion->>'date'")) and
          c.hidden == false and fragment("?::date", c.move_out_date) >= ^thirty_days_ago_on,
      order_by: [
        asc: c.move_out_date
      ]
    )
    |> Repo.all(prefix: client_schema)
  end

  def property_settings(%ClientSchema{
        name: client_schema,
        attrs: %Property{} = property
      }) do
    property = Repo.preload(property, [:setting], prefix: client_schema)

    if property.setting == nil do
      create_setting(ClientSchema.new(client_schema, property))
    else
      property.setting
    end
  end

  def update_property_settings(%Property{} = property, %ClientSchema{
        name: client_schema,
        attrs: attrs
      }) do
    setting =
      property_settings(ClientSchema.new(client_schema, property))
      |> update_setting(ClientSchema.new(client_schema, attrs))

    %{property | setting: setting}
  end

  def update_property_settings(property_id, %ClientSchema{
        name: client_schema,
        attrs: attrs
      })
      when is_integer(property_id) do
    property_id
    |> get()
    |> update_property_settings(%ClientSchema{
      name: client_schema,
      attrs: attrs
    })
  end

  defp create_setting(%ClientSchema{
         name: client_schema,
         attrs: %Property{} = property
       }) do
    %Setting{property_id: property.id}
    |> Repo.insert!(prefix: client_schema)
  end

  defp update_setting(%{property_id: property_id} = setting, %ClientSchema{
         name: client_schema,
         attrs: attrs
       }) do
    setting =
      setting
      |> Setting.changeset(attrs)
      |> Repo.update!(prefix: client_schema)

    AppCount.Core.PropertyTopic.property_changed(%{property_id: property_id}, __MODULE__)
    setting
  end
end
