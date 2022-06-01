defmodule AppCountWeb.LiveHelpers do
  import Phoenix.LiveView.Helpers

  @doc """
  Renders a component inside the `AppCountWeb.ModalComponent` component.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <%= live_modal @socket, AppCountWeb.OrdersLive.FormComponent,
        id: @orders.id || :new,
        action: @live_action,
        orders: @orders,
        return_to: Routes.orders_index_path(@socket, :index) %>
  """

  def live_modal(_socket, component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    modal_opts = [id: :modal, return_to: path, component: component, opts: opts]
    live_component(socket, AppCountWeb.ModalComponent, modal_opts)
  end

  def titleize(string) do
    string
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join(" ")
  end

  def get_completed_by(assignments, "maintenance") do
    assignment = hd(assignments)
    assignment["tech"]
  end
end
