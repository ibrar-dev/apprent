defmodule AppCountWeb.API.UploadController do
  use AppCountWeb, :controller
  alias AppCount.UploadServer

  def create(conn, %{"filename" => filename, "pieces" => num, "type" => type}) do
    json(conn, %{uuid: UploadServer.initialize_upload(num, filename, type)})
  end

  def update(conn, %{"slice" => %Plug.Upload{} = upload}) do
    case UploadServer.push_piece(upload) do
      :ok ->
        json(conn, %{})

      :error ->
        conn
        |> put_status(422)
        |> json(%{})
    end
  end

  def update(conn, %{"slice" => data, "uuid" => uuid, "num" => num}) do
    case UploadServer.push_piece(uuid, data, num) do
      :ok ->
        json(conn, %{})

      :error ->
        conn
        |> put_status(422)
        |> json(%{})
    end
  end
end
