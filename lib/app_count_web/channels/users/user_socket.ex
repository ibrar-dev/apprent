defmodule AppCountWeb.Users.UserSocket do
  use Phoenix.Socket

  channel("rewards:*", AppCountWeb.Users.RewardsChannel)

  def connect(params, socket) do
    case AppCount.Accounts.Utils.Tokens.verify_token(params["user_token"]) do
      {:error, :bad_token} -> :error
      {:ok, user, _} -> {:ok, assign(socket, :user, %{id: user.id})}
    end
  end

  def id(socket) do
    "user_socket:#{socket.assigns.user.id}"
  end
end
