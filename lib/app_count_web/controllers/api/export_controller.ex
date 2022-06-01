defmodule AppCountWeb.API.ExportController do
  use AppCountWeb, :controller
  alias AppCount.Exports

  def index(conn, _params) do
    json(conn, Exports.list_categories(conn.assigns.admin.id))
  end

  def create(conn, %{"category" => params}) do
    {:ok, category} =
      params
      |> Map.put("admin_id", conn.assigns.admin.id)
      |> Exports.insert_category()

    json(conn, %{category: Map.take(category, [:name, :id])})
  end

  def create(conn, %{"base64" => b64, "fileName" => filename, "contentType" => type} = params) do
    binary = Base.decode64!(b64)
    document = %{"uuid" => AppCount.Data.binary_to_upload(binary, filename, type)}

    Map.merge(params, %{
      "document" => document,
      "type" => type,
      "name" => filename,
      "binary" => binary
    })
    |> Exports.insert_document()
    |> case do
      {:ok, _} ->
        conn
        |> put_resp_content_type("application/octet-stream")
        |> put_resp_header("content-disposition", "inline;filename=#{filename}")
        |> send_resp(200, binary)

      {:error, _} ->
        conn
        |> put_status(422)
        |> json(%{error: "Invalid export"})
    end
  end

  def update(conn, %{"id" => id, "send" => send_params}) do
    Exports.send_document(id, send_params)
    json(conn, %{})
  end

  def show(conn, %{"id" => id}) do
    {filename, data} = Exports.download(id)

    conn
    |> put_resp_content_type("application/octet-stream")
    |> put_resp_header("content-disposition", "attachment;filename=#{filename}")
    |> send_resp(200, data)
  end

  def delete(conn, %{"id" => id}) do
    Exports.delete_document(id)
    |> handle_error(conn)
  end
end
