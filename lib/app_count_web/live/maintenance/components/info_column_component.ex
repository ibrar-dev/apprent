defmodule AppCountWeb.Maintenance.Components.InfoColumnComponent do
  use AppCountWeb, :live_component

  def render(assigns) do
    ~L"""
      <div class="card">
        <div class="card-body">
          <h5 class="card-title">Info</h5>
          <table class="table table-striped">
            <tr>
              <th>Status</th>
              <td><%= titleize(@order.status) %></td>
            </tr>
            <%= if @order.status == "completed" or @order.status == "assigned" do %>
              <tr>
                <th><%= titleize(@order.status) %></th>
                <td><%= get_completed_by(@order.assignments, @order.type) %></td>
              </tr>
            <% end %>
            <tr>
              <th>Ticket</th>
              <td>#<%= @order.ticket %></td>
            </tr>
            <%= if @order.unit.number do %>
              <tr>
                <th>Unit</th>
                <td><%= @order.unit.number %></td>
              </tr>
            <% end %>
            <tr>
              <th>Pet In Unit</th>
              <td>
                <%= if @order.has_pet do %>
                  <i class="fas fa-check text-success" />
                <% else %>
                  <i class="fas fa-times text-danger" />
                <% end %>
              </td>
            </tr>
            <tr>
              <th>Entry Allowed</th>
              <td>
                <%= if @order.entry_allowed do %>
                  <i class="fas fa-check text-success" />
                <% else %>
                  <i class="fas fa-times text-danger" />
                <% end %>
              </td>
            </tr>
          </table>
        </div>
      </div>
    """
  end
end
