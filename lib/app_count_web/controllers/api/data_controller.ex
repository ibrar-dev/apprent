defmodule AppCountWeb.API.DataController do
  use AppCountWeb, :controller
  alias AppCount.Data

  def create(conn, %{"html" => html}) do
    case Data.export_html(html) do
      {:ok, base64} -> json(conn, base64)
      {:error, error} -> handle_error({:error, error}, conn)
    end
  end
end
