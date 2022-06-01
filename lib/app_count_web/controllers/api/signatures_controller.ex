defmodule AppCountWeb.API.SignaturesController do
  use AppCountWeb, :public_controller

  def show(conn, %{"crypt" => crypt}) do
    case AppCountWeb.AppRent.decrypt(crypt) do
      :error ->
        put_status(conn, :unauthorized)
        |> text("bad crypt")

      {:ok, json} ->
        text(conn, AppCountWeb.Token.token(json))
    end
  end
end
