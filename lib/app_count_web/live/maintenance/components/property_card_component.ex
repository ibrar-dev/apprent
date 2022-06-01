defmodule AppCountWeb.Maintenance.Components.PropertyCardComponent do
  use AppCountWeb, :live_component

  def render(assigns) do
    ~L"""
      <div class="card">
        <%= if @order.property.logo do %>
          <img src="<%= @order.property.logo %>" class="card-img-top"  />
        <% end %>
        <div class="card-body">
          <h5 class="card-title"><%= @order.property.name %></h5>
          <div class="d-flex justify-content-between">
            <i class="fas fa-phone"></i>
            <a href="tel:<%= @order.property.phone %>"><%= @order.property.phone %></a>
          </div>
          <div class="d-flex justify-content-between">
            <i class="fas fa-globe"></i>
            <a target="_blank" href="<%= @order.property.website %>"><%= @order.property.website %></a>
          </div>
        </div>
      </div>
    """
  end
end
