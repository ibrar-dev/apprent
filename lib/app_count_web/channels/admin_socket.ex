defmodule AppCountWeb.AdminSocket do
  use Phoenix.Socket

  ## Channels
  # channel "room:*", AppCountWeb.RoomChannel
  channel("tech_admin", AppCountWeb.TechAdminChannel)
  channel("messages", AppCountWeb.MessagesChannel)
  channel("alerts", AppCountWeb.AlertsChannel)
  channel("alerts:*", AppCountWeb.AlertsChannel)
  channel("uploads", AppCountWeb.UploadChannel)

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(params, socket) do
    case AppCount.Admins.admin_from_token(params["token"]) do
      {:error, :bad_auth} -> :error
      admin -> {:ok, assign(socket, :admin, %{id: admin.id})}
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #       AppCountWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(socket) do
    "admin_socket:#{socket.assigns.admin["id"]}"
  end
end
