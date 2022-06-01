defmodule AppCountWeb.AdminMessagesChannel do
  use AppCountWeb, :channel

  def join(_topic, _message, socket) do
    {:ok, %{id: socket.assigns.admin["id"]}, socket}
  end

  def message_notification(admin_id, thread, message) do
    payload = %{thread: thread, message: message} |> AppCount.StructSerialize.serialize()
    AppCountWeb.Endpoint.broadcast("messages", "message:#{admin_id}", payload)
  end
end
