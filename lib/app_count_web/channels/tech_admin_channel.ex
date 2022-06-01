defmodule AppCountWeb.TechAdminChannel do
  use AppCountWeb, :channel

  def join(_topic, _message, socket) do
    {:ok, %{id: socket.assigns.admin["id"]}, socket}
  end
end
