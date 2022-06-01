defmodule AppCountWeb.API.TextMessageController do
  use AppCountWeb, :controller
  alias AppCount.Messaging.Utils.TextMessageSenders

  def show(conn, %{"id" => tenant_id, "offer_text_pay" => _}) do
    TextMessageSenders.offer_to_pay(tenant_id)
    |> case do
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(%{error: reason})

      _ ->
        json(conn, %{})
    end
  end
end
