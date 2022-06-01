defmodule AppCount.Maintenance.InsightReports.ProbeContext do
  import ShorterMaps
  alias AppCount.Core.DateTimeRange
  alias __MODULE__
  alias AppCount.Core.ClientSchema

  @deps %{
    property_repo: AppCount.Properties.PropertyRepo,
    assignment_repo: AppCount.Maintenance.AssignmentRepo,
    order_repo: AppCount.Maintenance.OrderRepo,
    cards_module: AppCount.Maintenance.Utils.Cards
  }

  @input_map %{
    property: nil,
    assignments: [],
    completion_time: nil,
    orders: [],
    open_orders: [],
    open_vendor_orders: [],
    date_range: nil,
    techs: [],
    unit_status: [],
    completed_orders: [],
    average_maintenance_rating: 0,
    completed_cards: [],
    submitted_work_orders_count: 0,
    callback_assignments: [],
    unit_tallies: %{
      ready: 0,
      not_ready: 0
    }
  }

  defstruct input: @input_map, comments: [], reading: []

  def input_map(extras \\ []) when is_list(extras) do
    extras_map = Map.new(extras)
    Map.merge(@input_map, extras_map)
  end

  # deprecated: use new/3 with input_map()
  def new(assignments, techs, property, date_range) do
    [assignments: assignments, techs: techs]
    |> input_map()
    |> new(property, date_range)
  end

  # new/3 only for tests
  def new(
        input_map,
        %{website: _, lat: _, lng: _} = property,
        %DateTimeRange{} = _date_range
      )
      when is_map(input_map) do
    input_map = %{input_map | property: property}

    %ProbeContext{input: input_map}
  end

  def load(property, date_range, deps \\ @deps) do
    client_schema = "dasmen"

    %{
      property_repo: property_repo,
      assignment_repo: assignment_repo,
      order_repo: order_repo,
      cards_module: cards_module
    } = deps

    # preload because the original load of property is complicated/obfuscated
    property = property_repo.preload(property)

    # Load
    orders = order_repo.get_aggregate_by_property(ClientSchema.new(client_schema, property.id))

    techs = property_repo.get_active_techs(ClientSchema.new(client_schema, property))

    unit_status =
      property_repo.unit_lease_status(ClientSchema.new(client_schema, property), date_range)

    open_orders = property_repo.open_maintenance_orders(ClientSchema.new(client_schema, property))

    open_vendor_orders =
      property_repo.open_vendor_orders(ClientSchema.new(client_schema, property))

    completion_time = property_repo.completion_time(property, date_range)
    completed_orders = property_repo.completed_orders(property, date_range)

    unit_tallies = cards_module.ready_and_not_ready_count(property)

    average_maintenance_rating =
      property_repo.get_average_maintenance_rating(property, date_range)

    submitted_work_orders_count = property_repo.get_submitted_work_orders(property, date_range)

    completed_cards =
      property_repo.completed_cards(ClientSchema.new(client_schema, property), date_range)

    callback_assignments = assignment_repo.get_callback_assignments(property, date_range)
    assignments = assignment_repo.get_property_assignments(property, date_range)

    ~M[ assignments,
        techs,
        property,
        date_range,
        unit_status,
        unit_tallies,
        orders,
        open_orders,
        open_vendor_orders,
        completion_time,
        completed_orders,
        average_maintenance_rating,
        completed_cards,
        submitted_work_orders_count,
        callback_assignments
      ]
    |> Map.to_list()
    |> input_map()
    |> new(property, date_range)
  end
end
