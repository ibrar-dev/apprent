defmodule AppCountWeb.Live.Maintenance.OrdersLive.Show do
  use AppCountWeb, :live_view
  alias AppCount.Maintenance
  alias AppCountWeb.Maintenance.Components

  def mount(%{"uuid" => uuid}, _session, socket) do
    order = Maintenance.get_order_public(uuid, nil)
    {:ok, assign(socket, page_title: "View Maintenance Request", order: order, open_modal: false)}
  end

  def handle_event("open-modal", _, socket), do: {:noreply, assign(socket, :open_modal, true)}
  def handle_event("close-modal", _, socket), do: {:noreply, assign(socket, :open_modal, false)}

  def handle_event(_e, _params, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~L"""
      <%= live_component @socket, AppCountWeb.NavBarComponent, assigns %>
      <div class="container">
        <div class="row mt-3">
          <div class="col">
            <div class="row">
              <div class="col">
                <%= live_component @socket, Components.PropertyCardComponent, assigns %>
              </div>
              <div class="col">
                <%= live_component @socket, Components.InfoColumnComponent, assigns %>
              </div>
            </div>
          </div>
        </div>
      </div>
    """
  end
end
