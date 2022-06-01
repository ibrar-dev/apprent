defmodule AppCountWeb.MaintenanceInsightReportLive do
  alias AppCount.Maintenance.InsightReports
  use AppCountWeb, :live_view

  def mount(_params, session, socket) do
    admin = session["admin"]
    properties = properties_for_admin(admin)

    # Start with all properties selected
    initial_ids = Enum.map(properties, fn prop -> prop.id end)

    filter_params = %{
      property_ids: initial_ids,
      start_date: nil,
      end_date: nil
    }

    socket =
      assign(
        socket,
        available_properties: properties,
        filter_params: filter_params,
        insight_reports: InsightReports.index(filter_params)
      )

    {
      :ok,
      socket
    }
  end

  def render(assigns) do
    ~L"""
    <div class="px-4 mt-4">
      <div class="row">
        <div class="col-xl-4">
          <%= property_filters(
            %{
              available_properties: @available_properties,
              property_ids: @filter_params[:property_ids]
            }
          ) %>
        </div>
        <div class="col-xl-4">
          <%= date_filters(
            %{
              start_date: @filter_params.start_date,
              end_date: @filter_params.end_date
            }
          ) %>
        </div>
      </div>
      <div class="row mt-4">
        <div class="col">
          <p><%= report_count(@insight_reports) %></p>
        </div>
      </div>
      <div class="row mt-2">
        <div class="col">
          <%= insight_report_list(%{list: @insight_reports, socket: @socket}) %>
        </div>
      </div>
    </div>
    """
  end

  def report_count(list) when length(list) == 1 do
    "Found 1 report"
  end

  def report_count(list) do
    "Found #{length(list)} reports"
  end

  def date_filters(assigns) do
    ~L"""
    <form phx-change="filter_by_date">
      <h3 class="mb-3 border-bottom">Filter by Date Range</h3>
      <div class="time-filters">
        <div class="form-group">
          <label for="start_date">Start of Range:</label>
          <input
            type="date"
            class="form-control"
            name="start_date"
            min="2020-08-27"
            max="<%= @end_date || AppCount.current_date() %>"
            pattern="\d{4}-\d{2}-\d{2}"
            value="<%= @start_date %>"
          >
        </div>
        <div class="form-group">
          <label for="end_date">End of Range:</label>
          <input
            type="date"
            class="form-control"
            name="end_date"
            min="<%= @start_date || "2020-08-27" %>"
            max="<%= AppCount.current_date() %>"
            pattern="\d{4}-\d{2}-\d{2}"
            value="<%= @end_date %>"
          >
        </div>
      </div>
    </form>
    """
  end

  def property_filters(assigns) do
    ~L"""
    <form phx-change="filter_property">
      <h3 class="mb-3 border-bottom">Filter by Property</h3>
      <div class="scrollable-checkboxes">
        <div class="form-group">
          <input type="hidden" name="property_ids[]" value="" />
          <%= for property <- @available_properties do %>
            <%= checkbox_for_property(%{property: property, checked: property.id in @property_ids}) %>
          <% end %>
        </div>
      </div>
    </form>
    <div class="check-buttons mt-2">
      <button class="btn btn-outline-danger" phx-click="select_no_properties">Select None</button>
      <button class="btn btn-outline-secondary" phx-click="select_all_properties">Select All</button>
    </div>
    """
  end

  # Args:
  #
  # + property - %{id: 123, name: "some property"}
  # + checked: true/false
  def checkbox_for_property(assigns) do
    # We include the hidden input to account for some weirdness with the HTTP
    # spec in cases where nothing is selected
    ~L"""
    <div class="form-check">
      <input
        class="form-check-input"
        type="checkbox"
        value="<%= @property.id %>"
        id="<%= @property.id %>"
        name="property_ids[]"
        <%= if @checked, do: "checked" %>
      />
      <label for="<%= @property.id %>"><%= @property.name %></label>
    </div>
    """
  end

  # Display for no available insight reports
  def insight_report_list(%{list: []} = assigns) do
    ~L"""
    <div class="w-50 mx-auto">
      <div class="card">
        <div class="card-body text-center">
          No Insight Reports available with the specified filters.
        </div>
      </div>
    </div>
    """
  end

  # Display for insight reports available!
  def insight_report_list(assigns) do
    ~L"""
    <div>
      <table class="table table-hover">
        <thead>
          <tr>
            <th scope="col">Property Name</th>
            <th scope="col">Action</th>
            <th scope="col">Issue Date</th>
            <th scope="col">Type</th>
          </tr>
        </thead>
        <tbody>
          <%= for report <- @list do %>
            <tr>
              <td>
                <%= report.property.name %>
              </td>
              <td>
                <%= link(
                  "See Report",
                  to: Routes.maintenance_insight_report_path(@socket, :show, report.id),
                  class: "btn btn-outline-primary")
                %>
              </td>
              <td>
                <%= formatted_date(report) %>
              </td>
              <td>
                <%= String.capitalize(report.type) %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  def handle_event("filter_property", %{"property_ids" => ids}, socket) do
    # Remap IDs
    property_ids =
      ids
      |> Enum.filter(fn id -> String.match?(id, ~r(\d+)) end)
      |> Enum.map(fn id -> String.to_integer(id) end)

    filter_params =
      Map.merge(
        socket.assigns.filter_params,
        %{property_ids: property_ids}
      )

    socket =
      assign(socket,
        filter_params: filter_params,
        insight_reports: InsightReports.index(filter_params)
      )

    {:noreply, socket}
  end

  def handle_event(
        "filter_by_date",
        %{"end_date" => end_date, "start_date" => start_date},
        socket
      ) do
    parsed_end_date = parse_date(end_date)
    parsed_start_date = parse_date(start_date)

    filter_params =
      Map.merge(
        socket.assigns.filter_params,
        %{
          start_date: parsed_start_date,
          end_date: parsed_end_date
        }
      )

    socket =
      assign(
        socket,
        filter_params: filter_params,
        insight_reports: InsightReports.index(filter_params)
      )

    {:noreply, socket}
  end

  def handle_event("select_no_properties", _, socket) do
    filter_params =
      Map.merge(
        socket.assigns.filter_params,
        %{property_ids: []}
      )

    socket =
      assign(socket,
        filter_params: filter_params,
        insight_reports: InsightReports.index(filter_params)
      )

    {:noreply, socket}
  end

  def handle_event("select_all_properties", _, socket) do
    all_props = socket.assigns.available_properties

    property_ids = Enum.map(all_props, fn prop -> prop.id end)

    filter_params =
      Map.merge(
        socket.assigns.filter_params,
        %{property_ids: property_ids}
      )

    socket =
      assign(socket,
        filter_params: filter_params,
        insight_reports: InsightReports.index(filter_params)
      )

    {:noreply, socket}
  end

  # Parsing an ISO-8601 datestring -- should be "YYYY-MM-DD", or possibly ""
  def parse_date(date_string) when is_binary(date_string) do
    parse_result = Date.from_iso8601(date_string)

    case parse_result do
      {:ok, date} ->
        date

      {:error, _} ->
        nil
    end
  end

  def parse_date(_) do
    nil
  end

  # Given an InsightReport with attached property, let's get the report's issue
  # date and make it human readable
  def formatted_date(report) do
    InsightReports.formatted_date(report)
  end

  def properties_for_admin(admin) do
    # TODO:SCHEMA
    AppCount.Core.ClientSchema.new("dasmen", admin)
    |> AppCount.Properties.list_active_properties()
    |> Enum.map(fn property -> %{id: property.id, name: property.name} end)
  end
end
