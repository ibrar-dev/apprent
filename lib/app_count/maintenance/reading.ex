defmodule AppCount.Maintenance.Reading do
  alias AppCount.Maintenance.Reading

  @derive {Jason.Encoder, only: [:name, :title, :display, :value, :link_path]}
  defstruct name: nil,
            measure: nil,
            title: "",
            display: "",
            value: 0,
            link_path: ""

  def valid_link_path?(%{link_path: link_path}) do
    _ = String.last(link_path) |> String.to_integer()
    true
  rescue
    _error in ArgumentError ->
      false
  end

  def put_property(readings, property_id) when is_list(readings) do
    readings
    |> Enum.map(fn reading ->
      put_property(reading, property_id)
    end)
  end

  def put_property(%Reading{link_path: link_path} = reading, property_id) do
    if valid_link_path?(reading) do
      reading
    else
      new_link_path = link_path <> "#{property_id}"
      %{reading | link_path: new_link_path}
    end
  end

  def new(name, {value, unit}, attrs) do
    attrs =
      attrs
      |> Keyword.put(:measure, {value, unit})
      |> Keyword.put(:value, value)
      |> Keyword.put(:name, name)

    struct(__MODULE__, attrs)
  end

  def build(report_name, value) do
    apply(__MODULE__, report_name, [value])
  end

  def work_order_saturation(value) do
    new(
      :work_order_saturation,
      {value, :percent},
      display: "percentage",
      link_path: "#",
      title: "Saturation"
    )
  end

  def property_name(name) do
    new(
      :property_name,
      {name, :text},
      display: "name",
      link_path: "#",
      title: "Property Name"
    )
  end

  def unit_count(value) do
    new(
      :unit_count,
      {value, :count},
      display: "number",
      link_path: "#",
      title: "Unit Count"
    )
  end

  def work_order_callbacks(value) do
    new(
      :work_order_callbacks,
      {value, :count},
      display: "number",
      link_path: "maintenance_reports?selected_properties=",
      title: "Callbacks submitted"
    )
  end

  def work_order_violations(value) do
    new(
      :work_order_violations,
      {value, :count},
      display: "number",
      link_path: "orders?search=violations&selected_properties=",
      title: "Open Violations"
    )
  end

  def make_ready_utilization(value) do
    new(
      :make_ready_utilization,
      {value, :percent},
      display: "percentage",
      link_path: "make_ready?selected_properties=",
      title: "Make Ready Utilization Percentage"
    )
  end

  def work_order_turnaround(value) do
    new(
      :work_order_turnaround,
      {value, :seconds},
      display: "duration",
      link_path: "orders?selected_properties=",
      title: "Average Open Ticket Duration"
    )
  end

  def work_order_completion_days(value) do
    new(
      :work_order_completion_days,
      {value, :seconds},
      display: "duration",
      link_path: "maintenance_reports?selected_properties=",
      title: "Average Work Order Completion Time"
    )
  end

  def make_ready_turnaround(seconds) do
    new(
      :make_ready_turnaround,
      {seconds, :seconds},
      display: "duration",
      link_path: "make_ready?selected_properties=",
      title: "Average Make Ready Completion Time"
    )
  end

  def make_ready_percent(value) do
    new(
      :make_ready_percent,
      {value, :percent},
      display: "percentage",
      link_path: "make_ready?selected_properties=",
      title: "Make Ready"
    )
  end

  def work_order_rating(value) do
    new(
      :work_order_rating,
      {value, :rating},
      display: "rating",
      link_path: "maintenance_reports?selected_properties=",
      title: "Average Rating - Past 30 Days"
    )
  end

  def unit_vacant(value) do
    new(
      :unit_vacant,
      {value, :count},
      display: "number",
      link_path: "make_ready?selected_properties=",
      title: "Total Vacant Units"
    )
  end

  def unit_vacant_not_ready(value) do
    new(
      :unit_vacant_not_ready,
      {value, :count},
      display: "number",
      link_path: "make_ready?selected_properties=",
      title: "Vacant Not Ready Units"
    )
  end

  def unit_vacant_ready(value) do
    new(
      :unit_vacant_ready,
      {value, :count},
      display: "number",
      link_path: "make_ready?selected_properties=",
      title: "Vacant Ready Units"
    )
  end

  def work_orders_submitted(value) do
    new(
      :work_orders_submitted,
      {value, :count},
      display: "number",
      link_path: "maintenance_reports?selected_properties=",
      title: "Work Orders Created Today"
    )
  end

  def work_orders(value) do
    new(
      :work_orders,
      {value, :count},
      display: "number",
      link_path: "orders?selected_properties=",
      title: "Open Work Orders"
    )
  end

  def work_order_completed(value) do
    new(
      :work_order_completed,
      {value, :count},
      display: "number",
      link_path: "maintenance_reports?selected_properties=",
      title: "Work Orders Completed Today"
    )
  end
end
